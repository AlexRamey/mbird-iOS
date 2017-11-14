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
    var attributedTitles: [NSAttributedString] = []
    var attributedAuthors: [NSAttributedString] = []
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
        
        
        // Set up a bar button item to toggle debug info on background app refresh
        let item = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(MBArticlesViewController.showTimestamps))
        self.navigationItem.setRightBarButton(item, animated: false)
        
        // 1. the managed context has to be passed in (UIApplication should only be accessed from main thread)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Unable to get the app delegate!")
            return
        }
        
        guard let managedContext = appDelegate.persistentContainer?.viewContext else {
            print("Unable to get the managed object context!")
            return
        }
  
        
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
                attributedTitles = articles.flatMap{ $0.title?.convertHtml() }
                attributedAuthors = articles.flatMap{ $0.author?.name?.convertHtml() }
                tableView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - showTimestamps() is used for debug purposes
    @objc func showTimestamps() {
        let lastOverallUpdate = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
        let lastBackgroundUpdate = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_BACKGROUND_APP_REFRESH_TIMESTAMP)
        let lastBackgroundAttempt = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_BACKGROUND_APP_REFRESH_ATTEMPT_TIMESTAMP)
        
        let lastOverallUpdateDate = Date(timeIntervalSinceReferenceDate: lastOverallUpdate)
        let lastBackgroundUpdateDate = Date(timeIntervalSinceReferenceDate: lastBackgroundUpdate)
        let lastBackgroundAttemptDate = Date(timeIntervalSinceReferenceDate: lastBackgroundAttempt)
        
        let dateFormatter = DateFormatter()
        if let timeZone = TimeZone(identifier: "America/New_York") {
            dateFormatter.timeZone = timeZone
        }
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let msg = "Last Update: \(dateFormatter.string(from: lastOverallUpdateDate))\nLast Background Refresh: \(dateFormatter.string(from: lastBackgroundUpdateDate))\nLast Background Attempt: \(dateFormatter.string(from: lastBackgroundAttemptDate))"
        
        let ac = UIAlertController(title: "DEBUG", message: msg, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "👍", style: .default, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension MBArticlesViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = articles[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: MBArticlesViewController.ArticleTableViewCellId) as? ArticleTableViewCell {
            let snippetEndIndex = article.content?.index(article.content!.startIndex, offsetBy: 200)
            let snippet = String(article.content!.prefix(through: snippetEndIndex!))
            cell.configure(title: attributedTitles[indexPath.row], author: attributedAuthors[indexPath.row], snippet: snippet, imageId: article.imageID, client: client, indexPath: indexPath)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedArticle = articles[indexPath.row]
        let action = SelectedArticle(article: selectedArticle)
        MBStore.sharedStore.dispatch(action)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

