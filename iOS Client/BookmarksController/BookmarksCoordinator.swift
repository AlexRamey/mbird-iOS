//
//  BookmarksCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import CoreData
import ReSwift
import SafariServices

class BookmarksCoordinator: NSObject, Coordinator, ArticlesTableViewDelegate, ArticleDetailDelegate, SFSafariViewControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var overlay: URL?
    let managedObjectContext: NSManagedObjectContext
    var articleDAO: ArticleDAO?
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.articleDAO = MBArticlesStore(context: managedObjectContext)
        super.init()
    }
    
    // MARK: - Coordinator
    func start() {
        let bookmarksController = MBBookmarksViewController.instantiateFromStoryboard()
        bookmarksController.managedObjectContext = self.managedObjectContext
        bookmarksController.delegate = self
        self.navigationController.pushViewController(bookmarksController, animated: true)
    }
    
    // MARK: - Bookmarks Table View Delegate
    func selectedArticle(_ article: Article) {
        let articleDetailVC = MBArticleDetailViewController.instantiateFromStoryboard(article: article, dao: self.articleDAO)
        articleDetailVC.delegate = self
        self.navigationController.pushViewController(articleDetailVC, animated: true)
    }
    
    // MARK: - Article Detail Delegate
    func selectedURL(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        self.navigationController.pushViewController(safariVC, animated: true)
    }
    
    // MARK: = SF Safari View Controller Delegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.navigationController.dismiss(animated: true, completion: nil)
    }
}
