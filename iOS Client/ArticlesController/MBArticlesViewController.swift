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
    static let ArticleTableViewCellId = "ArticleTableViewCell"
    
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
        
        tableView.register(UINib(nibName: MBArticlesViewController.ArticleTableViewCellId, bundle: nil), forCellReuseIdentifier: MBArticlesViewController.ArticleTableViewCellId)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = CGFloat(MBConstants.ARTICLE_TABLEVIEWCELL_HEIGHT)
        
        // 1. the managed context has to be passed in (UIApplication should only be accessed from main thread)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Unable to get the app delegate!")
            return
        }
        
        guard let persistentContainer = appDelegate.persistentContainer else {
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
            topLevelCategories = Array(articlesByCategory.keys)
            tableView.reloadData()
        }
    }
    
    private func groupArticlesByTopLevelCategoryName(articles: [MBArticle]) -> [String: [MBArticle]] {
        var retVal = [String: [MBArticle]]()
        
        articles.forEach { (article) in
            if let categories = article.categories {
                let topLevelCategories = Set(categories.flatMap({ (category) -> String? in
                    return (category as? MBCategory)?.getTopLevelCategory()?.name
                }))
            
                for topLevelCategory in topLevelCategories {
                    if let _ = retVal[topLevelCategory] {
                        retVal[topLevelCategory]?.append(article)
                    } else {
                        retVal[topLevelCategory] = [article]
                    }
                }
                
                if topLevelCategories.count == 0 {
                    print("Excluding article! \(article.title ?? "<no title>") b/c it has no categories")
                }
            } else {
                print("Excluding article \(article.title ?? "<no title>") b/c it has no categories")
            }
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
        return articlesByCategory[topLevelCategories[section]]!.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return topLevelCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = articlesByCategory[topLevelCategories[indexPath.section]]![indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: MBArticlesViewController.ArticleTableViewCellId) as? ArticleTableViewCell {
            let snippetEndIndex = article.content?.index(article.content!.startIndex, offsetBy: 200)
            let snippet = String(article.content!.prefix(through: snippetEndIndex!))
            cell.configure(title: article.title?.convertHtml(), author: article.author?.name?.convertHtml(), snippet: snippet, imageId: article.imageID, client: client, indexPath: indexPath)
            return cell
        } else {
            return UITableViewCell()
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedArticle = articlesByCategory[topLevelCategories[indexPath.section]]![indexPath.row]
        let action = SelectedArticle(article: selectedArticle)
        MBStore.sharedStore.dispatch(action)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        label.text = topLevelCategories[section]
        view.addSubview(label)
        view.backgroundColor = UIColor.orange
        return view
    }
}

