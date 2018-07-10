//
//  ArticlesCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import SafariServices
import CoreData

class ArticlesCoordinator: NSObject, Coordinator, UINavigationControllerDelegate, SFSafariViewControllerDelegate, ArticlesTableViewDelegate, ShowMoreArticlesDelegate, ArticleDetailDelegate {
    var childCoordinators: [Coordinator] = []
    var overlay: URL?
    var articleDAO: ArticleDAO
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(dao: ArticleDAO) {
        self.articleDAO = dao
        super.init()
    }
    
    // MARK: - Articles Table View Delegate
    func selectedArticle(_ article: Article) {
        let detailVC = MBArticleDetailViewController.instantiateFromStoryboard(article: article, dao: articleDAO)
        detailVC.delegate = self
        self.navigationController.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Show More Articles Delegate
    func showMoreArticlesForCategory(_ categoryName: String) {
        if let cat = self.articlesStore.getCategoryByName(categoryName) {
            let showMoreVC = ShowMoreViewController.instantiateFromStoryboard(store: self.articlesStore, category: cat)
            self.navigationController.pushViewController(showMoreVC, animated: true)
        }
    }
    
    // MARK: - Article Detail Delegate
    func selectedURL(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        self.navigationController.present(safariVC, animated: true, completion: nil)
    }
    
    // MARK: = SF Safari View Controller Delegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.navigationController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Coordinator
    func start() {
        let articlesController = MBArticlesViewController.instantiateFromStoryboard(dao: self.articleDAO)
        articlesController.delegate = self
        articlesController.showMoreDelegate = self
        self.navigationController.pushViewController(articlesController, animated: true)
    }
}
