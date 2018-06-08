//
//  ViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift
import CoreData
import Nuke
import Preheat

enum RowType {
    case featured
    case recent
    case categoryHeader
    case category
    case categoryFooter
}

class MBArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    // properties
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    
    var olderArticlesByCategory = [String: [MBArticle]]()
    var topLevelCategories: [String] = []
    
    var latestArticles: [MBArticle] = []
    let numLatest = 10
    let numOlderPerCategory = 5
    let featuredReuseIdentifier = "featuredReuseIdentifier"
    let recentReuseIdentifier = "recentReuseIdentifier"
    let categoryHeaderReuseIdentifier = "categoryHeaderReuseIdentifier"
    let categoryArticleReuseIdentifier = "categoryArticleReuseIdentifier"
    let categoryFooterReuseIdentifier = "categoryFooterReuseIdentifier"
    
    var currentState: ArticleState = MBArticleState()
    var isFirstAppearance = true
    
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UITableView>?
    
    // dependencies
    let client: MBClient = MBClient()
    var articlesStore: MBArticlesStore!

    static func instantiateFromStoryboard() -> MBArticlesViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as! MBArticlesViewController
        // swiftlint:enable force_cast
        vc.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "home-unselected"), selectedImage: UIImage(named: "home-selected"))
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)

        if isFirstAppearance {
            MBStore.sharedStore.dispatch(RefreshArticles(shouldMakeNetworkCall: true))
            isFirstAppearance = false
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(UINib(nibName: "FeaturedArticleTableViewCell", bundle: nil), forCellReuseIdentifier: featuredReuseIdentifier)
        tableView.register(UINib(nibName: "RecentArticleTableViewCell", bundle: nil), forCellReuseIdentifier: recentReuseIdentifier)
        tableView.register(UINib(nibName: "CategoryHeaderTableViewCell", bundle: nil), forCellReuseIdentifier: categoryHeaderReuseIdentifier)
        tableView.register(UINib(nibName: "CategoryArticleTableViewCell", bundle: nil), forCellReuseIdentifier: categoryArticleReuseIdentifier)
        tableView.register(UINib(nibName: "CategoryFooterTableViewCell", bundle: nil), forCellReuseIdentifier: categoryFooterReuseIdentifier)
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 235.0/255.0, green: 96.0/255.0, blue: 93.0/255.0, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Updating ...", attributes: nil)

        let articles = articlesStore.getArticles()
        MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: articles)))
        
        controller = Preheat.Controller(view: tableView)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
    }
    
    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.flatMap {
                var link: String?
                switch rowTypeForPath($0) {
                case .featured:
                    let article = latestArticles[$0.row]
                    link = article.imageLink ?? article.thumbnailLink
                case .recent, .category:
                    guard let article = articleForPath($0) else {
                        return nil
                    }
                    link = article.thumbnailLink ?? article.imageLink
                default:
                    break
                }
                
                guard let l = link, let url = URL(string: l) else {
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
    
    @objc private func refreshTableView(_ sender: Any) {
        if self.refreshControl.isRefreshing {
            MBStore.sharedStore.dispatch(RefreshArticles(shouldMakeNetworkCall: true))
        }
    }

    private func loadArticleData(makeNetworkCall: Bool) {
        let bgq = DispatchQueue.global(qos: .utility)
        bgq.async {
            if makeNetworkCall {
                    self.articlesStore.syncAllData().then { _ -> Void in
                        self.loadArticleDataFromDisk()
                    }.catch { syncErr in
                        print(syncErr)
                        MBStore.sharedStore.dispatch(LoadedArticles(articles: .error))
                    }
                }
            else {
                self.loadArticleDataFromDisk()
            }
        }
    }
    
    private func loadArticleDataFromDisk() {
        self.articlesStore.deleteOldArticles(completion: { (numDeleted) in
            print("Deleted \(numDeleted) old articles!!!")
            let loadedArticles = self.articlesStore.getArticles()
            MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: loadedArticles)))
        })
    }

    func newState(state: MBAppState) {
        switch state.articleState.articles {
        case .initial:
            break
        case .loading:
            if case .loading = self.currentState.articles {
                // do nothing
            } else if case .loadingFromDisk = self.currentState.articles {
                // do nothing
            } else {
                self.refreshControl.beginRefreshing()
                self.loadArticleData(makeNetworkCall: true)
            }
        case .loadingFromDisk:
            if case .loading = self.currentState.articles {
                // do nothing
            } else if case .loadingFromDisk = self.currentState.articles {
                // do nothing
            } else {
                self.refreshControl.beginRefreshing()
                self.loadArticleData(makeNetworkCall: false)
            }
        case .error:
            print("Error: Loading articles")
            self.refreshControl.endRefreshing()
        case .loaded(let data):
            latestArticles = getLatestArticles(articles: data)
            olderArticlesByCategory = groupArticlesByTopLevelCategoryName(articles: data)
            topLevelCategories = Array(olderArticlesByCategory.keys).sorted()
            tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
        
        self.currentState = state.articleState
    }
    
    private func getLatestArticles(articles: [MBArticle]) -> [MBArticle] {
        let articlesWithImages = articles.filter { (article) -> Bool in
            return article.imageID != 0
        }
        return Array(articlesWithImages.prefix(numLatest))
    }
    
    private func configureFeaturedCell(_ cell: FeaturedArticleTableViewCell, withArticle article: MBArticle, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title?.convertHtml())
        cell.setCategory(article.getTopLevelCategories().first)
        cell.setDate(date: article.date as Date?)
        
        cell.featuredImage.image = nil
        if let savedData = article.image?.image {
            cell.featuredImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.imageLink ?? article.thumbnailLink,
                  let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.featuredImage)
        } else if article.imageID != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }

    private func configureRecentCell(_ cell: RecentArticleTableViewCell, withArticle article: MBArticle, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title?.convertHtml())
        cell.setCategory(article.getTopLevelCategories().first)
        cell.setDate(date: article.date as Date?)
        
        cell.thumbnailImage.image = nil
        if let savedData = article.image?.image {
            cell.thumbnailImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.thumbnailLink ?? article.imageLink, let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageID != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }
    
    func configureCategoryHeaderCell(_ cell: CategoryHeaderTableViewCell, withCategory cat: String) {
        cell.setCategory(cat: cat)
    }
    
    private func configureCategoryArticleCell(_ cell: CategoryArticleTableViewCell, withArticle article: MBArticle, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title?.convertHtml())
        
        cell.thumbnailImage.image = nil
        if let savedData = article.image?.image {
            cell.thumbnailImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.thumbnailLink ?? article.imageLink,
                  let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageID != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }
    
    private func downloadImageForArticle(article: MBArticle, atIndexPath indexPath: IndexPath) {
        self.articlesStore.downloadImageURLsForArticle(article, withCompletion: { (url: URL?) in
            if url != nil {
                DispatchQueue.main.async {
                    if self.tableView.indexPathsForVisibleItems.contains(indexPath) {
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        })
    }
    
    private func groupArticlesByTopLevelCategoryName(articles: [MBArticle]) -> [String: [MBArticle]] {
        var retVal = [String: [MBArticle]]()
        
        let olderArticles = articles.filter { (article) -> Bool in
            return !latestArticles.contains(article)
        }
        
        olderArticles.forEach { (article) in
            article.getTopLevelCategories().forEach({ (cat) in
                if retVal[cat] == nil {
                    retVal[cat] = []
                }
                if let cnt = retVal[cat]?.count, cnt < numOlderPerCategory {
                    retVal[cat]?.append(article)
                }
            })
        }

        return retVal
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func rowTypeForPath(_ indexPath: IndexPath) -> RowType {
        if indexPath.section == 0 && indexPath.row == 0 {
            return .featured        // first overall row
        } else if indexPath.section == 0 {
            return .recent          // other rows in first section
        } else if indexPath.row == 0 {
            return .categoryHeader  // first row in other sections
        } else if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            return .categoryFooter  // last row in other sections
        } else {
            return .category        // middle rows in other sections
        }
    }
    
    private func articleForPath(_ indexPath: IndexPath) -> MBArticle? {
        switch rowTypeForPath(indexPath) {
        case .featured, .recent:
            return self.latestArticles[indexPath.row]
        case .category:
            let categoryName = topLevelCategories[indexPath.section - 1]
            if let articles = self.olderArticlesByCategory[categoryName] {
                return articles[indexPath.row - 1]
            }
        default:
            break
        }
        
        return nil
    }
}

extension MBArticlesViewController {
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return latestArticles.count
        }
        
        let categoryName = topLevelCategories[section - 1]
        return 2 + (olderArticlesByCategory[categoryName]?.count ?? 0)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return topLevelCategories.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rowTypeForPath(indexPath) {
        case .featured:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: featuredReuseIdentifier, for: indexPath) as? FeaturedArticleTableViewCell else {
                return UITableViewCell()
            }
            self.configureFeaturedCell(cell, withArticle: latestArticles[indexPath.row], atIndexPath: indexPath)
            return cell
        case .recent:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: recentReuseIdentifier, for: indexPath) as? RecentArticleTableViewCell else {
                return UITableViewCell()
            }
            self.configureRecentCell(cell, withArticle: latestArticles[indexPath.row], atIndexPath: indexPath)
            return cell
        case .categoryHeader:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryHeaderReuseIdentifier, for: indexPath) as? CategoryHeaderTableViewCell else {
                return UITableViewCell()
            }
            let categoryName = topLevelCategories[indexPath.section - 1]
            self.configureCategoryHeaderCell(cell, withCategory: categoryName)
            return cell
        case .categoryFooter:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryFooterReuseIdentifier, for: indexPath) as? CategoryFooterTableViewCell else {
                return UITableViewCell()
            }
            return cell
        case .category:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryArticleReuseIdentifier, for: indexPath) as? CategoryArticleTableViewCell else {
                return UITableViewCell()
            }
            if let article = articleForPath(indexPath) {
                self.configureCategoryArticleCell(cell, withArticle: article, atIndexPath: indexPath)
            }
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if rowTypeForPath(indexPath) == .categoryFooter {
            let selectedCategory = topLevelCategories[indexPath.section - 1]
            MBStore.sharedStore.dispatch(ShowMoreArticles(topLevelCategory: selectedCategory))
        } else if let article = articleForPath(indexPath) {
            let action = SelectedArticle(article: article)
            MBStore.sharedStore.dispatch(action)
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rowTypeForPath(indexPath) {
        case .featured:
            return 500.0
        case .recent, .category:
            return 200.0
        case .categoryHeader:
            return 80.0
        case .categoryFooter:
            return 86.0
        }
    }
}
