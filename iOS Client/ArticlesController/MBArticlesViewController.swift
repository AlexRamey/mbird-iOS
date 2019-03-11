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
// swiftlint:disable type_body_length
class MBArticlesViewController: UIViewController,
                                UISearchControllerDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()
    var isLoadingMore = false
    var isFirstAppearance = true
    var footerView: UIActivityIndicatorView?
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UICollectionView>?
    weak var delegate: ArticlesTableViewDelegate?
    var category: Category?
    var articles: [Article] = []
    
    // swiftlint:disable force_cast
    static let recentArticleSizingCell = UINib(nibName: "RecentArticleCollectionViewCell", bundle: nil).instantiate(withOwner: nil, options: nil).first! as! RecentArticleCollectionViewCell
    static let featuredArticleSizingCell = UINib(nibName: "FeaturedArticleCollectionViewCell", bundle: nil).instantiate(withOwner: nil, options: nil).first! as! FeaturedArticleCollectionViewCell
    
    // MARK: - Constants
    let featuredReuseIdentifier = "featuredReuseIdentifier"
    let recentReuseIdentifier = "recentReuseIdentifier"
    let categoryArticleReuseIdentifier = "categoryArticleReuseIdentifier"
    let articleCollectionViewReuseIdentifier = "RecentArticleCollectionViewCell"
    let featuredCollectionViewReuseIdentifier = "FeaturedArticleCollectionViewCell"
    
    // MARK: - Dependencies
    let client: MBClient = MBClient()
    var articlesStore: ArticleDAO!
    var authorDAO: AuthorDAO!
    var categoryDAO: CategoryDAO!
    var searchController: UISearchController?

    // MARK: - Initialization
    static func instantiateFromStoryboard(articleDAO: ArticleDAO, authorDAO: AuthorDAO, categoryDAO: CategoryDAO) -> MBArticlesViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as! MBArticlesViewController
        // swiftlint:enable force_cast
        viewController.articlesStore = articleDAO
        viewController.authorDAO = authorDAO
        viewController.categoryDAO = categoryDAO
        viewController.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "home-gray"), selectedImage: UIImage(named: "home-selected"))
        
        return viewController
    }
    
    // MARK: - UIViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar()
        configureSearchResultsController()
        configureCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // we have a default value set in the registration domain, so force-unwrap is safe
        let selectedCategoryName = UserDefaults.standard.string(forKey: MBConstants.SELECTED_CATEGORY_NAME_KEY)!
        
        var didCategoryChange = false
        if self.category?.name ?? "" != selectedCategoryName {
            didCategoryChange = true
            if selectedCategoryName != MBConstants.MOST_RECENT_CATEGORY_NAME,
                let selectedCategory = categoryDAO.getCategoryByName(selectedCategoryName) {
                self.category = selectedCategory
            } else {
                self.category = Category(categoryId: -1, name: MBConstants.MOST_RECENT_CATEGORY_NAME, parentId: 0)
            }
        }
        
        var navTitle = "Mockingbird"
        if let catName = self.category?.name,
            catName != MBConstants.MOST_RECENT_CATEGORY_NAME {
            navTitle = catName
        }
        navTitle = "\u{00B7}\u{00B7}\u{00B7}   \(navTitle.uppercased())   \u{00B7}\u{00B7}\u{00B7}"
        
        let navLabel = UILabel()
        navLabel.text = navTitle
        navLabel.font = UIFont(name: "AvenirNext-Bold", size: 18.0)
        navLabel.textColor = UIColor.MBOrange
        navLabel.adjustsFontSizeToFitWidth = true
        navLabel.minimumScaleFactor = 0.5
        self.navigationItem.titleView = navLabel
        
        if isFirstAppearance {
            isFirstAppearance = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.loadArticleDataFromDisk()
                // the following line ensures that the refresh control has the correct tint/text on first use
                self.refreshControl.beginRefreshing()
                self.nukeAndPave()
            }
        } else if didCategoryChange {
            self.loadArticleDataFromDisk()
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionView.reloadData()
    }
    
    // MARK: - View Configuration
    func configureSearchResultsController() {
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
    
    private func configureCollectionView() {
        collectionView.register(UINib(nibName: "RecentArticleCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: articleCollectionViewReuseIdentifier)
        collectionView.register(UINib(nibName: "FeaturedArticleCollectionViewCell", bundle: nil),
                                forCellWithReuseIdentifier: featuredCollectionViewReuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        refreshControl.attributedTitle = NSAttributedString(string: "Updating ...", attributes: nil)
        collectionView.isHidden = false
        controller = Preheat.Controller(view: collectionView)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
    }
    
    // MARK: - IBActions
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
    
    // called for subsequent refreshes (user pulls down refresh control)
    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        if sender.isRefreshing {
            guard let currentCategory = self.category else {
                print("there is no category")
                self.refreshControl.endRefreshing()
                return
            }
            
            var lineage: [Int] = []
            if currentCategory.name != MBConstants.MOST_RECENT_CATEGORY_NAME {
                lineage = [currentCategory.categoryId] + self.categoryDAO.getDescendentsOfCategory(cat: currentCategory).map { return $0.categoryId}
            }
            
            var afterArg: String?
            if let latestArticle = self.articles.first, latestArticle.date != "" {
                afterArg = latestArticle.date
            }
            
            self.client.getRecentArticles(inCategories: lineage, offset: 0, pageSize: 100, before: nil, after: afterArg, asc: true).then { recentArticles -> Void in
                self.processCandidateArticles(recentArticles, forCategory: currentCategory)
                }
                .always {
                    self.refreshControl.endRefreshing()
                }
                .catch { _ in
                    print("refresh articles failed . . .")
            }
        }
    }
    
    // MARK: - Data Management
    // called only once from viewDidLoad
    private func nukeAndPave() {
        self.articlesStore.nukeAndPave().then { _ -> Void in
            self.loadArticleDataFromDisk()
            }
            .always {
                self.refreshControl.endRefreshing()
            }
            .catch { _ in
                print("nuke and pave articles failed . . .")
        }
    }
    
    private func loadMore() {
        guard !self.isLoadingMore else { return }
        guard let currentCategory = self.category else {
            print("there is no category")
            return
        }
        self.isLoadingMore = true
        self.footerView?.startAnimating()

        var lineage: [Int] = []
        if currentCategory.name != MBConstants.MOST_RECENT_CATEGORY_NAME {
            lineage = [currentCategory.categoryId] + self.categoryDAO.getDescendentsOfCategory(cat: currentCategory).map { return $0.categoryId}
        }
        
        var offsetArg: Int = self.articles.count
        var beforeArg: String?
        if let earliestArticle = self.articles.last, earliestArticle.date != "" {
            beforeArg = earliestArticle.date
            offsetArg = 0 // we can use date instead
        }
        
        self.client.getRecentArticles(inCategories: lineage, offset: offsetArg, pageSize: 20, before: beforeArg, after: nil, asc: false).then { recentArticles -> Void in
            self.processCandidateArticles(recentArticles, forCategory: currentCategory)
            }
            .always {
                self.isLoadingMore = false
                self.footerView?.stopAnimating()
            }
            .catch { _ in
                print("loading more articles failed . . .")
        }
    }
    
    private func processCandidateArticles(_ candidateArticles: [Article], forCategory: Category) {
        // this is n^2 performance improvement opportunity if needed
        var newArticles = candidateArticles.filter({ (candidateArticle) -> Bool in
            return !self.articles.contains(where: { (existingArticle) -> Bool in
                return existingArticle.articleId == candidateArticle.articleId
            })
        })
        
        guard newArticles.count > 0 else { return }
        
        for index in 0..<newArticles.count {
            newArticles[index].resolveAuthor(dao: self.authorDAO)
            newArticles[index].resolveCategories(dao: self.categoryDAO)
        }
        
        self.client.getImagesById(newArticles.map {$0.imageId}, completion: { (images) in
            // note n^2 performance improvement opportunity if we need it
            for index in 0..<newArticles.count {
                newArticles[index].image = images.first(where: { (image) -> Bool in
                    newArticles[index].imageId == image.imageId
                })
            }
            
            DispatchQueue.main.async {
                // it's only safe to save 'most recent' category to disk;
                // saving articles for a specific category can cause there
                // to be holes on the most recent view. The next paging request
                // will assume the articles are sequential and basically
                // mash them down, covering up other potential articles and
                // resulting in non-productive duplicates being returned
                if forCategory.name == MBConstants.MOST_RECENT_CATEGORY_NAME {
                    _ = self.articlesStore.saveArticles(articles: newArticles)
                }
                
                // if the results are still relevant, then add them
                if self.category?.name ?? "" == forCategory.name {
                    self.articles = newArticles + self.articles
                    self.articles.sort { (articleI, articleJ) -> Bool in
                        if let iDate = articleI.getDate(), let jDate = articleJ.getDate() {
                            return iDate.compare(jDate) == .orderedDescending
                        } else if articleI.getDate() != nil {
                            return true // favor existant iDate over non-existant jDate
                        } else {
                            return false // favor existant jDate or consider these to be equal
                        }
                    }
                    self.collectionView.reloadData()
                }
            }
        })
    }
    
    private func loadArticleDataFromDisk() {
        guard let currentCategory = self.category else {
            return
        }
        if currentCategory.name == MBConstants.MOST_RECENT_CATEGORY_NAME {
            self.articles = self.articlesStore.getLatestArticles(skip: 0)
        } else {
            let lineage = [currentCategory.categoryId] + self.categoryDAO.getDescendentsOfCategory(cat: currentCategory).map { return $0.categoryId}
            self.articles = self.articlesStore.getLatestCategoryArticles(categoryIDs: lineage, skip: 0)
        }
        self.collectionView.reloadData()
    }
    
    // MARK: - TableView Cell Configuration
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
    
    private func configureCollectionViewCell(_ cell: RecentArticleCollectionViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.configure(title: article.title.convertHtml(),
                       category: article.categories.first?.name ?? "",
                       date: article.getDate())
        cell.thumbnailImage.image = nil
        if let url = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageId != 0 {
            self.downloadImageForArticle(article: article, atIndexPath: indexPath)
        }
    }
    
    private func configureFeaturedArticleCollectionViewCell(_ cell: FeaturedArticleCollectionViewCell, withArticle article: Article, atIndexPath indexPath: IndexPath) {
        cell.configure(title: article.title.convertHtml(),
                       category: article.categories.first?.name ?? "",
                       date: article.getDate())
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
                    if let idx = self.articles.index (where: { $0.articleId == article.articleId }) {
                        self.articles[idx].image = Image(imageId: article.imageId, thumbnailUrl: url)
                    }
                    
                    if let cell = self.collectionView.cellForItem(at: indexPath) as? ThumbnailImageCell {
                        Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
                    }
                }
            }
        })
    }
    
    private func rowTypeForPath(_ indexPath: IndexPath) -> RowType {
        if indexPath.section == 0 && indexPath.row % 13 == 0 {
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
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.articles.count
        return 0
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
        if let article = articleForPath(indexPath) {
            if let delegate = self.delegate {
                var context = self.category?.name
                if context ?? "" == MBConstants.MOST_RECENT_CATEGORY_NAME {
                    context = nil // no special context for most recent category
                }
                delegate.selectedArticle(article, categoryContext: context)
//                self.tableView.deselectRow(at: indexPath, animated: false)
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
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch rowTypeForPath(indexPath) {
        case .featured:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: featuredCollectionViewReuseIdentifier, for: indexPath) as? FeaturedArticleCollectionViewCell else {
                return UICollectionViewCell()
            }
            let article = articles[indexPath.row]
            configureFeaturedArticleCollectionViewCell(cell,
                                                       withArticle: article,
                                                       atIndexPath: indexPath)
            return cell
        case .recent, .category:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: articleCollectionViewReuseIdentifier, for: indexPath) as? RecentArticleCollectionViewCell else {
                return UICollectionViewCell()
            }
            let article = articles[indexPath.row]
            configureCollectionViewCell(cell,
                                        withArticle: article,
                                        atIndexPath: indexPath)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let article = articleForPath(indexPath) else {
            return CGSize.zero
        }
        
        if indexPath.row % 13 == 0 {
            let sizingCell = MBArticlesViewController.featuredArticleSizingCell
            sizingCell.prepareForReuse()
            configureFeaturedArticleCollectionViewCell(sizingCell,
                                                       withArticle: article,
                                                       atIndexPath: indexPath)
            sizingCell.layoutIfNeeded()
            var fittingSize = UILayoutFittingCompressedSize
            let width = view.bounds.width
            fittingSize.width = width
            let size = sizingCell.contentView.systemLayoutSizeFitting(fittingSize,
                                                                      withHorizontalFittingPriority: .required,
                                                                      verticalFittingPriority: .defaultLow)
            return CGSize(width: width, height: size.height)
        } else {
            let sizingCell = MBArticlesViewController.recentArticleSizingCell
            sizingCell.prepareForReuse()
            configureCollectionViewCell(sizingCell,
                                        withArticle: article,
                                        atIndexPath: indexPath)
            sizingCell.layoutIfNeeded()
            var fittingSize = UILayoutFittingCompressedSize
            let width = traitCollection.horizontalSizeClass == .regular ? (view.bounds.width/2) - 5 : view.bounds.width
            fittingSize.width = width
            let size = sizingCell.contentView.systemLayoutSizeFitting(fittingSize,
                                                                      withHorizontalFittingPriority: .required,
                                                                      verticalFittingPriority: .defaultLow)
            return CGSize(width: width, height: size.height)
        }
    }
}

protocol ArticlesTableViewDelegate: class {
    func selectedArticle(_ article: Article, categoryContext: String?)
}

protocol ThumbnailImageCell {
    var thumbnailImage: UIImageView! { get }
}
