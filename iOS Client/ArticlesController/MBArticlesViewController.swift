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

class MBArticlesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StoreSubscriber {
    // properties
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    var articlesByCategory = [String: [MBArticle]]()
    var topLevelCategories: [String] = []
    var currentState: ArticleState = MBArticleState()
    
    // dependencies
    let client: MBClient = MBClient()
    let articlesStore: MBArticlesStore = MBArticlesStore()
    var managedObjectContext: NSManagedObjectContext!
    
    // cell cache
    var cache = [Int:ArticleTableViewCell]()

    static func instantiateFromStoryboard() -> MBArticlesViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as! MBArticlesViewController
        // swiftlint:enable force_cast
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = CGFloat(MBConstants.ARTICLE_TABLEVIEWCELL_HEIGHT)
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red:235.0/255.0, green:96.0/255.0, blue:93.0/255.0, alpha:1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Articles ...", attributes: nil)
        
        let oneDayAgoTimestamp = Date().timeIntervalSinceReferenceDate - MBConstants.SECONDS_IN_A_DAY
        let lastUpdateTimestamp = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
        
        let articles = articlesStore.getArticles(managedObjectContext: self.managedObjectContext)
        MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: articles)))
        
        if lastUpdateTimestamp < oneDayAgoTimestamp || articles.count == 0 {
            MBStore.sharedStore.dispatch(RefreshArticles())
        }
    }
    
    @objc private func refreshTableView(_ sender: Any) {
        if self.refreshControl.isRefreshing {
            MBStore.sharedStore.dispatch(RefreshArticles())
        }
    }
    
    private func downloadArticleData() {
        let bgq = DispatchQueue.global(qos: .utility)
        bgq.async {
            self.articlesStore.syncAllData(managedObjectContext: self.managedObjectContext).then { isNewData -> Void in
                // Update timestamp
                let timestamp: Double = Date().timeIntervalSinceReferenceDate
                UserDefaults.standard.set(timestamp, forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
                print("IS NEW DATA? \(isNewData)")
                
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
            if case Loaded<[MBArticle]>.loading = self.currentState.articles {
                // do nothing
            } else {
                self.refreshControl.beginRefreshing()
                self.downloadArticleData()
            }
        case .error:
            print("Error: Loading articles")
            self.refreshControl.endRefreshing()
        case .loaded(let data):
            print("New Data for table view")
            articlesByCategory = groupArticlesByTopLevelCategoryName(articles: data)
            topLevelCategories = Array(articlesByCategory.keys).sorted()
            tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
        
        self.currentState = state.articleState
    }
    
    private func groupArticlesByTopLevelCategoryName(articles: [MBArticle]) -> [String: [MBArticle]] {
        var retVal = [String: [MBArticle]]()
        
        articles.forEach { (article) in
            article.getTopLevelCategories().forEach {
                if retVal[$0] == nil {
                    retVal[$0] = []
                }
                retVal[$0]?.append(article)
            }
        }
        
        // sort newest articles first
        retVal.keys.forEach { retVal[$0] = retVal[$0]?.sorted { return ($0.date as Date? ?? Date.distantPast) > ($1.date as Date? ?? Date.distantPast) } }

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
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return topLevelCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = cache[indexPath.section] {
            return cell
        }
        
        // swiftlint:disable force_cast
        let cell = Bundle.main.loadNibNamed("ArticleTableViewCell", owner: self, options: nil)![0] as! ArticleTableViewCell
        // swiftlint:enable force_cast
        cell.configure(articles: articlesByCategory[topLevelCategories[indexPath.section]]!)
        cache[indexPath.section] = cell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return topLevelCategories[section]
    }
}
