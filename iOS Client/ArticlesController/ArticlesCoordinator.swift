//
//  ArticlesCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import SafariServices

class ArticlesCoordinator: NSObject, Coordinator, UINavigationControllerDelegate, SFSafariViewControllerDelegate, ArticlesTableViewDelegate, ShowMoreArticlesDelegate, ArticleDetailDelegate {
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
    func selectedArticle(_ article: Article) {
        let detailVC = MBArticleDetailViewController.instantiateFromStoryboard(article: article, dao: self.articleDAO)
        detailVC.delegate = self
        self.navigationController.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Show More Articles Delegate
    func showMoreArticlesForCategory(_ categoryName: String) {
        if let cat = self.categoryDAO.getCategoryByName(categoryName) {
            let showMoreVC = ShowMoreViewController.instantiateFromStoryboard(articleDAO: self.articleDAO, categoryDAO: self.categoryDAO, category: cat)
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
        let articlesController = MBArticlesViewController.instantiateFromStoryboard(articleDAO: self.articleDAO, authorDAO: self.authorDAO, categoryDAO: self.categoryDAO)
        articlesController.delegate = self
        articlesController.showMoreDelegate = self
        self.navigationController.pushViewController(articlesController, animated: true)
    }
}
