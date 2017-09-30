//
//  ArticlesCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

class ArticlesCoordinator: NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
       return UINavigationController()
    }()
    
    // MARK: - Coordinator
    func start() {
        let articlesController = MBArticlesViewController.instantiateFromStoryboard()
        self.navigationController.pushViewController(articlesController, animated: true)
    }
}
