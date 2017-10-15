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
    var articles: [MBArticle] = []
    
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
        
        // 1. the managed context has to be passed in (UIApplication should only be accessed from main thread)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Unable to get the app delegate!")
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
  
        
        let oneWeekAgoTimestamp = Date().timeIntervalSinceReferenceDate - MBConstants.SECONDS_IN_A_WEEK
        let lastUpdateTimestamp = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
        
        if lastUpdateTimestamp > oneWeekAgoTimestamp {
            let articles = MBStore().getArticles(managedContext: managedContext)
            
            if articles.count > 0 {
                MBStore.sharedStore.dispatch(LoadedArticles(articles: .loaded(data: articles)))
                return
            }
        }
        
        downloadArticleData(managedContext: managedContext)
    }
    
    private func downloadArticleData(managedContext: NSManagedObjectContext) {
        MBStore().syncAllData(context: managedContext) { (isNewData: Bool, err: Error?) in
            if let syncErr = err {
                print(syncErr)
                MBStore.sharedStore.dispatch(LoadedArticles(articles: .error))
                return
            }
            
            // TODO: Run Data Cleanup Task
            // Update timestamp
            let timestamp: Double = Date().timeIntervalSinceReferenceDate
            UserDefaults.standard.set(timestamp, forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
            
            print("IS NEW DATA? \(isNewData)")
            let loadedArticles = MBStore().getArticles(managedContext: managedContext)
            DispatchQueue.main.async {
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
            if data.count != articles.count {
                print("New Data for table view")
                articles = data
                tableView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK - UITableViewDataSource
extension MBArticlesViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = articles[indexPath.row]
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableViewCell") as! UITableViewCell
        // swiftlint:enable force_cast
        cell.textLabel?.text = article.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedArticle = articles[indexPath.row]
        let action = SelectedArticle(article: selectedArticle)
        MBStore.sharedStore.dispatch(action)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
