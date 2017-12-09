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
    @IBOutlet weak var tableView: UITableView!
    var articlesByCategory = [String: [MBArticle]]()
    var topLevelCategories: [String] = []
    let client = MBClient()
    let reuseIdentifier = "ArticleCellReuseIdentifier"
    
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
        
        tableView.register(UINib(nibName: "ArticleTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = CGFloat(MBConstants.ARTICLE_TABLEVIEWCELL_HEIGHT)
        

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let persistentContainer = appDelegate.persistentContainer else {
            print("Unable to get the persistent container!")
            return
        }
        
        let oneWeekAgoTimestamp = Date().timeIntervalSinceReferenceDate - MBConstants.SECONDS_IN_A_WEEK
        let lastUpdateTimestamp = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
        
        if lastUpdateTimestamp > oneWeekAgoTimestamp {
            let articles = MBStore().getArticles(persistentContainer: persistentContainer)
            
            if articles.count > 0 {
                MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: articles)))
                return
            }
        }
        
        downloadArticleData(persistentContainer: persistentContainer)
    }
    
    private func downloadArticleData(persistentContainer: NSPersistentContainer) {
        MBStore().syncAllData(persistentContainer: persistentContainer) { (isNewData: Bool?, err: Error?) in
            if let syncErr = err {
                print(syncErr)
                DispatchQueue.main.async {
                    // ReSwift recommends always dispatching from the main thread
                    MBStore.sharedStore.dispatch(LoadedArticles(articles: .error))
                }
                return
            }
            
            // TODO: Run Data Cleanup Task
            // Update timestamp
            let timestamp: Double = Date().timeIntervalSinceReferenceDate
            UserDefaults.standard.set(timestamp, forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
            print("IS NEW DATA? \(isNewData ?? false)")
            
            DispatchQueue.main.async {
                // ReSwift recommends always dispatching from the main thread
                let loadedArticles = MBStore().getArticles(persistentContainer: persistentContainer)
                MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: loadedArticles)))
            }
        }
    }

    func newState(state: MBAppState) {
        switch state.articleState.articles {
        case .initial:
            break //Do nothing if articles haven't tried to load
        case .loading:
            break //Do something here to indicate loading
        case .error:
            print("Error: Loading articles")
        case .loaded(let data):
            print("New Data for table view")
            articlesByCategory = groupArticlesByTopLevelCategoryName(articles: data)
            topLevelCategories = Array(articlesByCategory.keys).sorted()
            tableView.reloadData()
        }
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
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! ArticleTableViewCell
        // swiftlint:enable force_cast
        cell.configure(articles: articlesByCategory[topLevelCategories[indexPath.section]]!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return topLevelCategories[section]
    }
}
