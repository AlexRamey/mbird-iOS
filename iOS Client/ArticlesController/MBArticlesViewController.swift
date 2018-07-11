//
//  ViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import CoreData
import Nuke
import Preheat

enum RowType {
    case featured
    case recent
    case category
    case categoryFooter
}

class MBArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, HeaderViewDelegate, UISearchControllerDelegate {
    // properties
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    
    var olderArticlesByCategory = [String: [Article]]()
    var topLevelCategories: [String] = []
    
    var latestArticles: [Article] = []
    let numLatest = 10
    let numOlderPerCategory = 5
    let featuredReuseIdentifier = "featuredReuseIdentifier"
    let recentReuseIdentifier = "recentReuseIdentifier"
    let sectionHeaderReuseIdentifier = "sectionHeaderReuseIdentifier"
    let categoryArticleReuseIdentifier = "categoryArticleReuseIdentifier"
    let categoryFooterReuseIdentifier = "categoryFooterReuseIdentifier"
    
    var isFirstAppearance = true
    var selectedIndexPath: IndexPath?
    
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UITableView>?
    var searchBarHolder: SearchBarHolder?
    weak var delegate: ArticlesTableViewDelegate?
    weak var showMoreDelegate: ShowMoreArticlesDelegate?
    
    // dependencies
    let client: MBClient = MBClient()
    var articlesStore: ArticleDAO!
    var authorDAO: AuthorDAO!
    var categoryDAO: CategoryDAO!
    var searchController: UISearchController?

    static func instantiateFromStoryboard(articleDAO: ArticleDAO, authorDAO: AuthorDAO, categoryDAO: CategoryDAO) -> MBArticlesViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as! MBArticlesViewController
        // swiftlint:enable force_cast
        vc.articlesStore = articleDAO
        vc.authorDAO = authorDAO
        vc.categoryDAO = categoryDAO
        vc.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "home-gray"), selectedImage: UIImage(named: "home-selected"))
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(UINib(nibName: "FeaturedArticleTableViewCell", bundle: nil), forCellReuseIdentifier: featuredReuseIdentifier)
        tableView.register(UINib(nibName: "RecentArticleTableViewCell", bundle: nil), forCellReuseIdentifier: recentReuseIdentifier)
        tableView.register(UINib(nibName: "SectionHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: sectionHeaderReuseIdentifier)
        tableView.register(UINib(nibName: "CategoryArticleTableViewCell", bundle: nil), forCellReuseIdentifier: categoryArticleReuseIdentifier)
        tableView.register(UINib(nibName: "CategoryFooterTableViewCell", bundle: nil), forCellReuseIdentifier: categoryFooterReuseIdentifier)
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 235.0/255.0, green: 96.0/255.0, blue: 93.0/255.0, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Updating ...", attributes: nil)
        
        controller = Preheat.Controller(view: tableView)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
        
        let searchResultsController = SearchResultsTableViewController.instantiateFromStoryboard(authorDAO: self.authorDAO, categoryDAO: self.categoryDAO)
        searchResultsController.delegate = self.delegate
        self.searchController = UISearchController(searchResultsController: searchResultsController)
        self.searchController?.hidesNavigationBarDuringPresentation = false
        self.searchController?.dimsBackgroundDuringPresentation = false
        if let searchBar = self.searchController?.searchBar {
            searchResultsController.searchBar = searchBar
            searchBar.backgroundImage = UIImage()
            searchBar.isTranslucent = false
        }
        self.searchController?.searchResultsUpdater = searchResultsController
        self.searchController?.delegate = self
        self.definesPresentationContext = true
        
        self.loadArticleDataFromDisk()
    }
    
    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.compactMap {
                var url: URL?
                switch rowTypeForPath($0) {
                case .featured:
                    guard let article = articleForPath($0) else {
                        return nil
                    }
                    url = article.image?.imageUrl ?? article.image?.thumbnailUrl
                case .recent, .category:
                    guard let article = articleForPath($0) else {
                        return nil
                    }
                    url = article.image?.thumbnailUrl ?? article.image?.imageUrl
                default:
                    break
                }
                
                if let resolvedURL = url {
                    var request = Request(url: resolvedURL)
                    request.priority = .low
                    return request
                }
                
                return nil
            }
        }
        
        preheater.startPreheating(with: requests(for: added))
        preheater.stopPreheating(with: requests(for: removed))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if isFirstAppearance {
            // the following line ensures that the refresh control has the correct tint/text on first use
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
            
            self.refreshControl.beginRefreshing()
            self.refreshTableView(self.refreshControl)
            isFirstAppearance = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        controller?.enabled = true
        if let indexPath = self.selectedIndexPath {
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.selectedIndexPath = nil
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // When you disable preheat controller it removes all preheating
        // index paths and calls its handler
        controller?.enabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        if sender.isRefreshing {
            self.articlesStore.syncAllData().then { isNewData -> Void in
                if isNewData {
                    self.loadArticleDataFromDisk()
                }
            }
            .always {
                self.refreshControl.endRefreshing()
            }
            .catch { _ in
                    print("refresh articles failed . . .")
            }
        }
    }
    
    private func loadArticleDataFromDisk() {
        self.articlesStore.deleteOldArticles(completion: { (numDeleted) in
            print("Deleted \(numDeleted) old articles!!!")
            DispatchQueue.main.async {
                let articles = self.articlesStore.getArticles()
                self.latestArticles = self.getLatestArticles(articles: articles)
                let olderArticles = articles.filter { (article) -> Bool in
                    return !self.latestArticles.contains { $0.id == article.id }
                }
                self.olderArticlesByCategory = self.groupArticlesByTopLevelCategoryName(articles: olderArticles)
                self.topLevelCategories = Array(self.olderArticlesByCategory.keys).sorted()
                self.tableView.reloadData()
            }
        })
    }
    
    private func getLatestArticles(articles: [Article]) -> [Article] {
        let articlesWithImages = articles.filter { (article) -> Bool in
            return article.imageId != 0
        }
        return Array(articlesWithImages.prefix(numLatest))
    }
    
    private func configureFeaturedCell(_ cell: FeaturedArticleTableViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title.convertHtml())
        cell.setCategory(article.categories.first?.name)
        cell.setDate(date: article.getDate())
        
        cell.featuredImage.image = nil
        if let url = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: url, into: cell.featuredImage)
        } else if article.imageId != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }

    private func configureRecentCell(_ cell: RecentArticleTableViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title.convertHtml())
        cell.setCategory(article.categories.first?.name)
        cell.setDate(date: article.getDate())
        
        cell.thumbnailImage.image = nil
        if let url = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageId != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }
    
    private func configureCategoryArticleCell(_ cell: CategoryArticleTableViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title.convertHtml())
        
        cell.thumbnailImage.image = nil
        if let url = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageId != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }
    
    private func downloadImageForArticle(article: Article, atIndexPath indexPath: IndexPath) {
        self.articlesStore.downloadImageURLsForArticle(article, withCompletion: { (url: URL?) in
            if let url = url {
                DispatchQueue.main.async {
                    self.setArticleImageURL(article, url: url)
                    if self.tableView.indexPathsForVisibleItems.contains(indexPath) {
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        })
    }
    
    private func setArticleImageURL(_ article: Article, url: URL) {
        if let idx = self.latestArticles.index (where: { $0.id == article.id }) {
            self.latestArticles[idx].image = Image(id: article.imageId, thumbnailUrl: url, imageUrl: nil)
        }
        
        for key in self.topLevelCategories {
            if let categoryArticles = self.olderArticlesByCategory[key] {
                self.olderArticlesByCategory[key] = categoryArticles.map {
                    var mutableItem = $0
                    if $0.id == article.id {
                        mutableItem.image = Image(id: $0.imageId, thumbnailUrl: url, imageUrl: nil)
                    }
                    return mutableItem
                }
            }
        }
    }
    
    private func groupArticlesByTopLevelCategoryName(articles: [Article]) -> [String: [Article]] {
        var retVal = [String: [Article]]()
        
        articles.forEach { (article) in
            article.categories.forEach({ (cat) in
                if retVal[cat.name] == nil {
                    retVal[cat.name] = []
                }
                if let cnt = retVal[cat.name]?.count, cnt < numOlderPerCategory {
                    retVal[cat.name]?.append(article)
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
        } else if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            return .categoryFooter  // last row in other sections
        } else {
            return .category        // middle rows in other sections
        }
    }
    
    private func articleForPath(_ indexPath: IndexPath) -> Article? {
        switch rowTypeForPath(indexPath) {
        case .featured, .recent:
            return self.latestArticles[indexPath.row]
        case .category:
            let categoryName = topLevelCategories[indexPath.section - 1]
            if let articles = self.olderArticlesByCategory[categoryName] {
                return articles[indexPath.row]
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
        return 1 + (olderArticlesByCategory[categoryName]?.count ?? 0)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return topLevelCategories.count + 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderReuseIdentifier) as? SectionHeaderView else {
            return nil
        }
        if section == 0 {
            header.setSearchVisible(isVisible: true)
            header.setText("Mockingbird")
            header.delegate = self
            self.searchBarHolder = header
        } else {
            header.setSearchVisible(isVisible: false)
            header.setText(self.topLevelCategories[section - 1])
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
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
    
    // MARK: - UISearchControllerDelegate
    func didDismissSearchController(_ searchController: UISearchController) {
        print("DID DISMISS")
        self.searchBarHolder?.removeSearchBar()
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        if rowTypeForPath(indexPath) == .categoryFooter {
            if let showMoreDelegate = self.showMoreDelegate {
                let selectedCategory = topLevelCategories[indexPath.section - 1]
                showMoreDelegate.showMoreArticlesForCategory(selectedCategory)
            }
        } else if let article = articleForPath(indexPath) {
            if let delegate = self.delegate {
                delegate.selectedArticle(article)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rowTypeForPath(indexPath) {
        case .featured:
            return 500.0
        case .recent, .category:
            return 200.0
        case .categoryFooter:
            return 86.0
        }
    }
    
    // MARK: HeaderViewDelegate
    func searchTapped(sender: SectionHeaderView) -> UISearchBar? {
        guard !self.refreshControl.isRefreshing else {
            return nil // search bar looks weird if it comes while the section header is too low
        }
        return self.searchController?.searchBar
    }
}

protocol ArticlesTableViewDelegate: class {
    func selectedArticle(_ article: Article)
}

protocol ShowMoreArticlesDelegate: class {
    func showMoreArticlesForCategory(_ category: String)
}
