//
//  ViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import Nuke
import Preheat
import PromiseKit

enum RowType {
    case featured
    case recent
    case category
}

class MBArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate {
    // properties
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    
    var category: Category?
    var articles: [Article] = []
    
    let featuredReuseIdentifier = "featuredReuseIdentifier"
    let recentReuseIdentifier = "recentReuseIdentifier"
    let categoryArticleReuseIdentifier = "categoryArticleReuseIdentifier"
    
    var selectedIndexPath: IndexPath?
    
    var isLoadingMore = false
    var isFirstAppearance = true
    var footerView: UIActivityIndicatorView?
    
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UITableView>?
    weak var delegate: ArticlesTableViewDelegate?
    
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
        
        configureNavBar()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(UINib(nibName: "FeaturedArticleTableViewCell", bundle: nil), forCellReuseIdentifier: featuredReuseIdentifier)
        tableView.register(UINib(nibName: "RecentArticleTableViewCell", bundle: nil), forCellReuseIdentifier: recentReuseIdentifier)
        tableView.register(UINib(nibName: "CategoryArticleTableViewCell", bundle: nil), forCellReuseIdentifier: categoryArticleReuseIdentifier)
        
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
        self.searchController?.hidesNavigationBarDuringPresentation = true
        self.searchController?.dimsBackgroundDuringPresentation = true
        if let searchBar = self.searchController?.searchBar {
            searchResultsController.searchBar = searchBar
            searchBar.backgroundImage = UIImage()
            searchBar.searchBarStyle = .default
            searchBar.barTintColor = UIColor.white
            searchBar.tintColor = UIColor.MBSalmon
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
                guard let article = articleForPath($0) else {
                    return nil
                }
                if let resolvedURL = article.image?.thumbnailUrl {
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
    
    private func configureNavBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: nil, action: nil)
        
        let filter = UIBarButtonItem(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(self.filterTapped(sender:)))
        
        let search = UIBarButtonItem(image: UIImage(named: "search-binoculars"), style: .plain, target: self, action: #selector(self.searchTapped(sender:)))
        
        self.navigationItem.leftBarButtonItem = filter
        self.navigationItem.rightBarButtonItem = search
    }
    
    @objc func filterTapped(sender: UIBarButtonItem) {
        let filterVC = SelectCategoryViewController.instantiateFromStoryboard(categoryDAO: self.categoryDAO)
        self.present(filterVC, animated: true, completion: nil)
    }
    
    @objc func searchTapped(sender: UIBarButtonItem) {
        if let searchBar = self.searchController?.searchBar {
            self.view.addSubview(searchBar)
            searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // we have a default value set in the registration domain, so force-unwrap is safe
        let selectedCategoryName = UserDefaults.standard.string(forKey: MBConstants.SELECTED_CATEGORY_NAME_KEY)!
        
        if self.category?.name ?? "" != selectedCategoryName {
            if selectedCategoryName != MBConstants.MOST_RECENT_CATEGORY_NAME,
                let selectedCategory = categoryDAO.getCategoryByName(selectedCategoryName) {
                self.category = selectedCategory
            } else {
                self.category = Category(id: -1, name: MBConstants.MOST_RECENT_CATEGORY_NAME, parentId: 0)
            }
            self.loadArticleDataFromDisk()
        }
        
        var navTitle = "Mockingbird"
        if let catName = self.category?.name,
            catName != MBConstants.MOST_RECENT_CATEGORY_NAME {
            navTitle = catName
        }
        navTitle = "\u{00B7}\u{00B7}\u{00B7}   \(navTitle.uppercased())   \u{00B7}\u{00B7}\u{00B7}"
        
        var navLabel = UILabel()
        navLabel.text = navTitle
        navLabel.font = UIFont(name: "AvenirNext-Bold", size: 18.0)
        navLabel.textColor = UIColor.MBOrange
        navLabel.adjustsFontSizeToFitWidth = true
        navLabel.minimumScaleFactor = 0.5
        self.navigationItem.titleView = navLabel
        
        if isFirstAppearance {
            isFirstAppearance = false
            // the following line ensures that the refresh control has the correct tint/text on first use
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
            
            self.refreshControl.beginRefreshing()
            self.refreshTableView(self.refreshControl)
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
    }
    
    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        if sender.isRefreshing {
            self.articlesStore.nukeAndPave().then { articles -> Void in
                self.articles = articles
                self.tableView.reloadData()
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
        guard let currentCategory = self.category else {
            return
        }
        
        if currentCategory.name == MBConstants.MOST_RECENT_CATEGORY_NAME {
            self.articles = self.articlesStore.getLatestArticles(skip: 0)
        } else {
            let lineage = [currentCategory.id] + self.categoryDAO.getDescendentsOfCategory(cat: currentCategory).map { return $0.id}
            self.articles = self.articlesStore.getLatestCategoryArticles(categoryIDs: lineage, skip: 0)
        }
        
        self.tableView.reloadData()
    }
    
    private func configureFeaturedCell(_ cell: FeaturedArticleTableViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.setTitle(article.title.convertHtml())
        if self.category?.name ?? "" == MBConstants.MOST_RECENT_CATEGORY_NAME {
            cell.setCategory(article.categories.first?.name)
        } else {
            cell.setCategory(self.category?.name)
        }
        
        cell.setDate(date: article.getDate())
        
        cell.thumbnailImage.image = nil
        if let url = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
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
                    if let idx = self.articles.index (where: { $0.id == article.id }) {
                        self.articles[idx].image = Image(id: article.imageId, thumbnailUrl: url)
                    }
                    
                    if let cell = self.tableView.cellForRow(at: indexPath) as? ThumbnailImageCell {
                        Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
                    }
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadMore() {
//        if !self.isLoadingMore {
//            self.isLoadingMore = true
//            self.footerView?.startAnimating()
//            self.loadMoreArticlesWithCompletion { () -> Void in
//                DispatchQueue.main.async {
//                    self.footerView?.stopAnimating()
//                    self.isLoadingMore = false
//                }
//            }
//        }
    }
    
//    private func loadMoreArticlesWithCompletion(_ completion: @escaping () -> Void) {
//        guard let currentCategory = self.category else {
//            completion()
//            return
//        }
//        var restriction: [Category] = []
//        if currentCategory.name != MBConstants.MOST_RECENT_CATEGORY_NAME {
//            restriction = [currentCategory] + self.categoryDAO.getDescendentsOfCategory(cat: currentCategory)
//        }
//        firstly {
//            self.articlesStore.syncLatestArticles(categoryRestriction: restriction, offset: self.articles.count)
//        }.then { isNewData -> Void in
//                if isNewData && self.category?.name ?? "" == currentCategory.name {
//                    DispatchQueue.main.async {
//                        var newArticles: [Article] = []
//
//                        if currentCategory.name == MBConstants.MOST_RECENT_CATEGORY_NAME {
//                            newArticles = self.articlesStore.getLatestArticles(skip: self.articles.count)
//                        } else {
//                            newArticles = self.articlesStore.getLatestCategoryArticles(categoryIDs: restriction.map { $0.id }, skip: self.articles.count)
//                        }
//
//                        self.addMoreArticles(newArticles)
//                    }
//                }
//                completion()
//            }.catch { error in
//                print("Error loading more articles: \(error)")
//                completion()
//        }
//    }
    
//    private func addMoreArticles(_ newArticles: [Article]) {
//        if newArticles.count > 0 {
//            newArticles.forEach { (newArticle) in
//                if !self.articles.contains { $0.id == newArticle.id } {
//                    self.articles.append(newArticle)
//                }
//            }
//            self.articles.sort { (articleI, articleJ) -> Bool in
//                if let iDate = articleI.getDate(), let jDate = articleJ.getDate() {
//                    return iDate.compare(jDate) == .orderedDescending
//                } else if articleI.getDate() != nil {
//                    return true // favor existant iDate over non-existant jDate
//                } else {
//                    return false // favor existant jDate or consider these to be equal
//                }
//            }
//            self.tableView.reloadData()
//        }
//    }
    
    private func rowTypeForPath(_ indexPath: IndexPath) -> RowType {
        if indexPath.section == 0 && indexPath.row == 0 {
            return .featured
        } else if let catName = self.category?.name, catName == MBConstants.MOST_RECENT_CATEGORY_NAME {
            return .recent
        } else {
            return .category
        }
    }
    
    private func articleForPath(_ indexPath: IndexPath) -> Article? {
        guard self.articles.count > indexPath.row else {
            return nil
        }
        return self.articles[indexPath.row]
    }
}

extension MBArticlesViewController {
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rowTypeForPath(indexPath) {
        case .featured:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: featuredReuseIdentifier, for: indexPath) as? FeaturedArticleTableViewCell else {
                return UITableViewCell()
            }
            self.configureFeaturedCell(cell, withArticle: self.articles[indexPath.row], atIndexPath: indexPath)
            return cell
        case .recent:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: recentReuseIdentifier, for: indexPath) as? RecentArticleTableViewCell else {
                return UITableViewCell()
            }
            self.configureRecentCell(cell, withArticle: self.articles[indexPath.row], atIndexPath: indexPath)
            return cell
        case .category:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryArticleReuseIdentifier, for: indexPath) as? CategoryArticleTableViewCell else {
                return UITableViewCell()
            }
            self.configureCategoryArticleCell(cell, withArticle: self.articles[indexPath.row], atIndexPath: indexPath)
            return cell
        }
    }
    
    // MARK: - UISearchControllerDelegate
    func didDismissSearchController(_ searchController: UISearchController) {
        if let searchBar = self.searchController?.searchBar {
            searchBar.removeFromSuperview()
        }
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        if searchController.searchBar.superview?.frame.origin.y != 0.0 {
            searchController.searchBar.superview?.frame.origin = CGPoint(x: 0.0, y: 0.0)
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        if let article = articleForPath(indexPath) {
            if let delegate = self.delegate {
                var context = self.category?.name
                if context ?? "" == MBConstants.MOST_RECENT_CATEGORY_NAME {
                    context = nil // no special context for most recent category
                }
                delegate.selectedArticle(article, categoryContext: context)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rowTypeForPath(indexPath) {
        case .featured:
            return 500.0
        default:
            return 200.0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == self.articles.count {
            self.loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.footerView == nil {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            spinner.hidesWhenStopped = true
            self.footerView = spinner
        }
        return self.footerView
    }
}

protocol ArticlesTableViewDelegate: class {
    func selectedArticle(_ article: Article, categoryContext: String?)
}

protocol ThumbnailImageCell {
    var thumbnailImage: UIImageView! { get }
}
