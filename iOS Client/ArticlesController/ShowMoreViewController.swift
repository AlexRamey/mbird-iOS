//
//  ShowMoreViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/16/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import PromiseKit
import Nuke
import Preheat

class ShowMoreViewController: UITableViewController {
    var articleDAO: ArticleDAO!
    var categoryDAO: CategoryDAO!
    var currentCategory: Category!
    var articles: [Article] = []
    var categoryIDs: [Int] = []
    var isLoadingMore = false
    var footerView: UIActivityIndicatorView?
    let categoryArticleReuseIdentifier = "categoryArticleReuseIdentifier"
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UITableView>?
    weak var delegate: ArticlesTableViewDelegate?
    
    static func instantiateFromStoryboard(articleDAO: ArticleDAO, categoryDAO: CategoryDAO, category: Category) -> ShowMoreViewController {
        // swiftlint:disable force_cast
        let showMoreVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShowMoreViewController") as! ShowMoreViewController
        // swiftlint:enable force_cast
        showMoreVC.articleDAO = articleDAO
        showMoreVC.categoryDAO = categoryDAO
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
            return indexPaths.compactMap {
                let article = self.articles[$0.row]
                
                guard let url = article.image?.thumbnailUrl else {
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
    
    private func configureCell(_ cell: CategoryArticleTableViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title.convertHtml())
        
        cell.thumbnailImage.image = nil
        if let imageLink = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: imageLink, into: cell.thumbnailImage)
        } else if article.imageId != 0 {
            self.articleDAO.downloadImageURLsForArticle(article, withCompletion: { (url: URL?) in
                if url != nil {
                    DispatchQueue.main.async {
                        self.articles = self.articles.map({ (item) -> Article in
                            var mutableItem = item
                            if item.id == article.id {
                                mutableItem.image = Image(id: item.imageId, thumbnailUrl: url!, imageUrl: nil)
                            }
                            return mutableItem
                        })
                        if self.tableView.indexPathsForVisibleItems.contains(indexPath) {
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                }
            })
        }
    }
    
    private func loadArticles() {
        // Load articles we already have into the table view (catArticles)
        self.categoryIDs = [self.currentCategory.id] + self.categoryDAO.getDescendentsOfCategory(cat: self.currentCategory).map { return $0.id }
        self.articles = self.articleDAO.getLatestCategoryArticles(categoryIDs: self.categoryIDs, skip: 0)
        self.tableView.reloadData()
        if self.articles.count < 10 {
            self.loadMore()
        }
    }
    
    private func loadMoreArticlesWithCompletion(_ completion: @escaping () -> Void) {
        firstly {
            self.articleDAO.syncCategoryArticles(categories: self.categoryIDs, excluded: self.articles.map { $0.id })
        }.then { isNewData -> Void in
            if isNewData {
                DispatchQueue.main.async {
                    let newArticles = self.articleDAO.getLatestCategoryArticles(categoryIDs: self.categoryIDs, skip: self.articles.count)
                    self.addMoreArticles(newArticles)
                }
            }
            completion()
        }.catch { error in
            print("Error loading more articles: \(error)")
            completion()
        }
    }
    
    private func addMoreArticles(_ newArticles: [Article]) {
        if newArticles.count > 0 {
            newArticles.forEach { (newArticle) in
                if !self.articles.contains { $0.id == newArticle.id } {
                    self.articles.append(newArticle)
                }
            }
            self.articles.sort { (articleI, articleJ) -> Bool in
                if let iDate = articleI.getDate(), let jDate = articleJ.getDate() {
                    return iDate.compare(jDate) == .orderedDescending
                } else if articleI.getDate() != nil {
                    return true // favor existant iDate over non-existant jDate
                } else {
                    return false // favor existant jDate or consider these to be equal
                }
            }
            self.tableView.reloadData()
        }
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
            delegate.selectedArticle(articles[indexPath.row], categoryContext: self.currentCategory.name)
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
