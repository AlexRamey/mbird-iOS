//
//  ArticlesCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import SafariServices

class ArticlesCoordinator: NSObject, Coordinator, UINavigationControllerDelegate, SFSafariViewControllerDelegate, ArticlesTableViewDelegate, ArticleDetailDelegate {
    var childCoordinators: [Coordinator] = []
    var overlay: URL?
    var articleDAO: ArticleDAO
    var authorDAO: AuthorDAO
    var categoryDAO: CategoryDAO
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(articleDAO: ArticleDAO, authorDAO: AuthorDAO, categoryDAO: CategoryDAO) {
        self.articleDAO = articleDAO
        self.authorDAO = authorDAO
        self.categoryDAO = categoryDAO
        super.init()
    }
    
    // MARK: - Articles Table View Delegate
    func selectedArticle(_ article: Article, categoryContext: String?) {
        let detailVC = MBArticleDetailViewController.instantiateFromStoryboard(article: article, categoryContext: categoryContext, dao: self.articleDAO)
        detailVC.delegate = self
        self.navigationController.pushViewController(detailVC, animated: true)
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
        let articlesController = MBArticlesViewController.instantiateFromStoryboard(articleDAO: self.articleDAO, authorDAO: self.authorDAO, categoryDAO: self.categoryDAO)
        articlesController.delegate = self
        self.navigationController.pushViewController(articlesController, animated: true)
    }
}
