//
//  ShowMoreViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/16/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import CoreData
import UIKit
import PromiseKit
import ReSwift
import Nuke
import Preheat

class ShowMoreViewController: UITableViewController {
    typealias StoreSubscriberStateType = ArticleState
    var articlesStore: MBArticlesStore!
    var currentCategory: MBCategory!
    var articles: [MBArticle] = []
    var categoryIDs: [Int] = []
    var isLoadingMore = false
    var footerView: UIActivityIndicatorView?
    let categoryArticleReuseIdentifier = "categoryArticleReuseIdentifier"
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UITableView>?
    weak var delegate: ArticlesTableViewDelegate?
    
    static func instantiateFromStoryboard(store: MBArticlesStore, category: MBCategory) -> ShowMoreViewController {
        // swiftlint:disable force_cast
        let showMoreVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShowMoreViewController") as! ShowMoreViewController
        // swiftlint:enable force_cast
        showMoreVC.articlesStore = store
        showMoreVC.currentCategory = category
        return showMoreVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "CategoryArticleTableViewCell", bundle: nil), forCellReuseIdentifier: categoryArticleReuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        
        controller = Preheat.Controller(view: tableView)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
        
        self.title = self.currentCategory.name
        self.loadArticles()
    }
    
    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.flatMap {
                let article = self.articles[$0.row]
                
                guard let link = article.thumbnailLink ?? article.imageLink,
                    let url = URL(string: link) else {
                        return nil
                }
                
                var request = Request(url: url)
                request.priority = .low
                return request
            }
        }
        
        preheater.startPreheating(with: requests(for: added))
        preheater.stopPreheating(with: requests(for: removed))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        controller?.enabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // When you disable preheat controller it removes all preheating
        // index paths and calls its handler
        controller?.enabled = false
    }
    
    private func configureCell(_ cell: CategoryArticleTableViewCell, withArticle article: MBArticle, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title?.convertHtml())
        
        cell.thumbnailImage.image = nil
        if let savedData = article.image?.image {
            cell.thumbnailImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.thumbnailLink ?? article.imageLink,
            let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageID != 0 {
            self.articlesStore?.downloadImageURLsForArticle(article, withCompletion: { (url: URL?) in
                if url != nil {
                    DispatchQueue.main.async {
                        if self.tableView.indexPathsForVisibleItems.contains(indexPath) {
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            })
        }
    }
    
    private func loadArticles() {
        self.categoryIDs = []
        var catArticles: Set<MBArticle> = []
        // DFS through the category tree rooted at currentCategory
        // to acquire the ids of all children categories and collect
        // any articles we already have associated with those categories
        var stack: [MBCategory] = [self.currentCategory]
        while let current = stack.popLast() {
            self.categoryIDs.append(Int(current.categoryID))
            if let articles = current.articles as? Set<MBArticle> {
                catArticles.formUnion(articles)
            }
            if let children = current.children?.allObjects as? [MBCategory] {
                stack.append(contentsOf: children)
            }
        }
        
        // Load articles we already have into the table view (catArticles)
        self.articles = sortedByDate(articles: catArticles)
        self.tableView.reloadData()
        
        if self.articles.count < 10 {
            self.loadMore()
        }
    }
    
    private func loadMoreArticlesWithCompletion(_ completion: @escaping () -> Void) {
        guard let store = self.articlesStore else {
            completion()
            return
        }
        
        firstly {
            store.syncCategoryArticles(categories: self.categoryIDs, excluded: self.articles.map {Int($0.articleID)} )
        }.then { isNewData -> Void in
            if isNewData {
                DispatchQueue.main.async {
                    let newArticles = store.getCategoryArticles(categoryIDs: self.categoryIDs, skip: self.articles.count)
                    self.addMoreArticles(newArticles)
                }
            }
            completion()
        }.catch { error in
            print("Error loading more articles: \(error)")
            completion()
        }
    }
    
    private func addMoreArticles(_ newArticles: [MBArticle]) {
        if newArticles.count > 0 {
            let existingArticles = Set<MBArticle>(self.articles)
            let newSet = existingArticles.union(newArticles)
            self.articles = sortedByDate(articles: newSet)
            self.tableView.reloadData()
        }
    }
    
    private func sortedByDate(articles: Set<MBArticle>) -> [MBArticle] {
        return articles.sorted(by: { (articleI, articleJ) -> Bool in
            if let iDate = articleI.date as Date?, let jDate = articleJ.date as Date? {
                return iDate.compare(jDate) == .orderedDescending
            } else if articleI.date != nil {
                return true // favor existant iDate over non-existant jDate
            } else if articleJ.date != nil {
                return false // favor existant jDate over non-existant iDate
            } else {
                return false // consider these to be equal since both dates are non-present
            }
        })
    }
    
    private func loadMore() {
        if !self.isLoadingMore {
            self.isLoadingMore = true
            self.footerView?.startAnimating()
            self.loadMoreArticlesWithCompletion { () -> Void in
                DispatchQueue.main.async {
                    self.footerView?.stopAnimating()
                    self.isLoadingMore = false
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryArticleReuseIdentifier, for: indexPath) as? CategoryArticleTableViewCell else {
            return UITableViewCell()
        }
        self.configureCell(cell, withArticle: self.articles[indexPath.row], atIndexPath: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = self.delegate {
            delegate.selectedArticle(articles[indexPath.row].toDomain())
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == articles.count {
            self.loadMore()
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.footerView == nil {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            spinner.hidesWhenStopped = true
            self.footerView = spinner
        }
        return self.footerView
    }
}
