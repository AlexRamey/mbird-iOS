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
    let articlesStore: MBArticlesStore = MBArticlesStore()
    var managedObjectContext: NSManagedObjectContext!

    static func instantiateFromStoryboard() -> MBArticlesViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as! MBArticlesViewController
        // swiftlint:enable force_cast
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)

        if isFirstAppearance {
            MBStore.sharedStore.dispatch(RefreshArticles())
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
        self.title = "Articles"
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
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Articles ...", attributes: nil)

        let articles = articlesStore.getArticles(managedObjectContext: self.managedObjectContext)
        MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: articles)))
        
        controller = Preheat.Controller(view: tableView)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
    }
    
    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.flatMap {
                if $0.section != 0 && $0.row == 0 {
                    // category headers
                    return nil
                }
                
                if $0.section != 0 && $0.row == self.tableView(tableView, numberOfRowsInSection: $0.section) - 1 {
                    // category footers
                    return nil
                }
                
                var a: MBArticle?
                
                if $0.section == 0 {
                    // recent articles
                    a = latestArticles[$0.row]
                } else {
                    // category articles
                    let categoryName = topLevelCategories[$0.section - 1]
                    if let articles = olderArticlesByCategory[categoryName] {
                        a = articles[$0.row - 1]
                    }
                }
                
                guard let article = a else {
                    return nil
                }
                
                var l: String?
                
                if $0.section == 0 && $0.row == 0 {
                    l = article.imageLink ?? article.thumbnailLink
                } else {
                    l = article.thumbnailLink ?? article.imageLink
                }
                
                guard let imageLink = l, let url = URL(string: imageLink) else {
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
            MBStore.sharedStore.dispatch(RefreshArticles())
        }
    }

    private func downloadArticleData() {
        let bgq = DispatchQueue.global(qos: .utility)
        bgq.async {
            self.articlesStore.syncAllData(managedObjectContext: self.managedObjectContext).then { _ -> Void in
                self.articlesStore.deleteOldArticles(managedObjectContext: self.managedObjectContext, completion: { (numDeleted) in
                    print("Deleted \(numDeleted) old articles!!!")
                    let loadedArticles = self.articlesStore.getArticles(managedObjectContext: self.managedObjectContext)
                    MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: loadedArticles)))
                })
            }.catch { syncErr in
                print(syncErr)
                MBStore.sharedStore.dispatch(LoadedArticles(articles: .error))
            }
        }
    }

    func newState(state: MBAppState) {
        switch state.articleState.articles {
        case .initial:
            break
        case .loading:
            if case .loading = self.currentState.articles {
                // do nothing
            } else {
                self.refreshControl.beginRefreshing()
                self.downloadArticleData()
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
    
    private func configureFeaturedCell(_ cell: FeaturedArticleTableViewCell, withArticle article: MBArticle) {
        cell.articleID = article.articleID
        
        cell.categoryLabel.textColor = UIColor.black
        cell.categoryLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        cell.categoryLabel.text = article.getTopLevelCategories().first ?? "mockingbird"
        
        cell.timeLabel.textColor = UIColor.black
        cell.timeLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        
        if let date = article.date {
            if date.timeIntervalSinceNow > -16 * 3600 {
                // just show time if it was published recently
                cell.timeLabel.text = DateFormatter.localizedString(from: date as Date, dateStyle: .none, timeStyle: .short)
            } else {
                // just show date otherwise
                var longDate = DateFormatter.localizedString(from: date as Date, dateStyle: .long, timeStyle: .none)
                if let idx = longDate.index(of: ",") {
                    longDate = String(longDate.prefix(upTo: idx))
                }
                cell.timeLabel.text = longDate
            }
        } else {
            cell.timeLabel.text = "recent"
        }
        
        cell.titleLabel.attributedText = article.title?.convertHtml()
        cell.titleLabel.textColor = UIColor.MBOrange
        cell.titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .heavy)
        cell.titleLabel.sizeToFit()
        
        cell.featuredImage.image = nil
        
        if let savedData = article.image?.image {
            cell.featuredImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.imageLink, let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.featuredImage)
        } else if article.imageID != 0 {
            self.client.getImageURLs(imageID: Int(article.imageID)) { links in
                DispatchQueue.main.async {
                    if let context = article.managedObjectContext {
                        do {
                            article.thumbnailLink = links?[0]
                            article.imageLink = links?[1]
                            try context.save()
                        } catch {
                            print("😅 unable to save image url for \(article.articleID)")
                        }
                    }
                    if cell.articleID == article.articleID, let imageLink = article.imageLink ?? article.thumbnailLink, let imageURL = URL(string: imageLink) {
                        Manager.shared.loadImage(with: imageURL, into: cell.featuredImage)
                    }
                }
            }
        }
    }

    private func configureRecentCell(_ cell: RecentArticleTableViewCell, withArticle article: MBArticle) {
        cell.articleID = article.articleID
        
        cell.categoryLabel.textColor = UIColor.black
        cell.categoryLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        cell.categoryLabel.text = article.getTopLevelCategories().first ?? "mockingbird"
        
        cell.titleLabel.attributedText = article.title?.convertHtml()
        cell.titleLabel.textColor = UIColor.MBOrange
        cell.titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        cell.titleLabel.sizeToFit()
        
        cell.thumbnailImage.image = nil
        
        if let savedData = article.image?.image {
            cell.thumbnailImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.thumbnailLink, let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageID != 0 {
            self.client.getImageURLs(imageID: Int(article.imageID)) { links in
                DispatchQueue.main.async {
                    if let context = article.managedObjectContext {
                        do {
                            article.thumbnailLink = links?[0]
                            article.imageLink = links?[1]
                            try context.save()
                        } catch {
                            print("😅 unable to save image url for \(article.articleID)")
                        }
                    }
                    if cell.articleID == article.articleID, let imageLink = article.thumbnailLink ?? article.imageLink, let imageURL = URL(string: imageLink) {
                        Manager.shared.loadImage(with: imageURL, into: cell.thumbnailImage)
                    }
                }
            }
        }
    }
    
    private func configureCategoryArticleCell(_ cell: CategoryArticleTableViewCell, withArticle article: MBArticle) {
        cell.articleID = article.articleID
        
        cell.titleLabel.attributedText = article.title?.convertHtml()
        cell.titleLabel.textColor = UIColor.MBOrange
        cell.titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        cell.titleLabel.sizeToFit()
        
        cell.thumbnailImage.image = nil
        
        if let savedData = article.image?.image {
            cell.thumbnailImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.thumbnailLink, let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        } else if article.imageID != 0 {
            self.client.getImageURLs(imageID: Int(article.imageID)) { links in
                DispatchQueue.main.async {
                    if let context = article.managedObjectContext {
                        do {
                            article.thumbnailLink = links?[0]
                            article.imageLink = links?[1]
                            try context.save()
                        } catch {
                            print("😅 unable to save image url for \(article.articleID)")
                        }
                    }
                    if cell.articleID == article.articleID, let imageLink = article.thumbnailLink ?? article.imageLink, let imageURL = URL(string: imageLink) {
                        Manager.shared.loadImage(with: imageURL, into: cell.thumbnailImage)
                    }
                }
            }
        }
    }
    
    func configureCategoryCell(_ cell: CategoryHeaderTableViewCell, withCategory cat: String) {
        cell.backgroundColor = UIColor.black
        cell.categoryLabel.textColor = UIColor.MBBlue
        cell.categoryLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .heavy)
        cell.categoryLabel.text = cat
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
        if indexPath.section == 0 && indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: featuredReuseIdentifier, for: indexPath) as? FeaturedArticleTableViewCell else {
                return UITableViewCell()
            }
            
            self.configureFeaturedCell(cell, withArticle: latestArticles[indexPath.row])
            
            return cell
        } else if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: recentReuseIdentifier, for: indexPath) as? RecentArticleTableViewCell else {
                return UITableViewCell()
            }
            
            self.configureRecentCell(cell, withArticle: latestArticles[indexPath.row])
            
            return cell
        } else if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryHeaderReuseIdentifier, for: indexPath) as? CategoryHeaderTableViewCell else {
                return UITableViewCell()
            }
            let categoryName = topLevelCategories[indexPath.section - 1]
            self.configureCategoryCell(cell, withCategory: categoryName)
            return cell
        } else if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryFooterReuseIdentifier, for: indexPath) as? CategoryFooterTableViewCell else {
                return UITableViewCell()
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: categoryArticleReuseIdentifier, for: indexPath) as? CategoryArticleTableViewCell else {
                return UITableViewCell()
            }
            
            let categoryName = topLevelCategories[indexPath.section - 1]
            if let articles = olderArticlesByCategory[categoryName] {
                self.configureCategoryArticleCell(cell, withArticle: articles[indexPath.row - 1])
            }
            
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let selectedArticle = self.latestArticles[indexPath.row]
            let action = SelectedArticle(article: selectedArticle)
            MBStore.sharedStore.dispatch(action)
        } else if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
            print("Show More: \(indexPath.section)")
        } else if indexPath.row != 0 {
            let categoryName = topLevelCategories[indexPath.section - 1]
            if let articles = olderArticlesByCategory[categoryName] {
                let selectedArticle = articles[indexPath.row - 1]
                let action = SelectedArticle(article: selectedArticle)
                MBStore.sharedStore.dispatch(action)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 500.0 // featured
        } else if indexPath.row == 0 {
            return 80.0 // category header
        } else if indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1 {
                // category footer
                return 86.0
        } else {
            return 200.0 // article cell
        }
    }
}
