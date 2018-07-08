//
//  AppCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class AppCoordinator: NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController {
        return self.tabBarController
    }
    var articleDAO: ArticleDAO?
    let window: UIWindow
    let managedObjectContext: NSManagedObjectContext
    
    private lazy var tabBarController: MBTabBarController = {
        let tabBarController = MBTabBarController.instantiateFromStoryboard()
        return tabBarController
    }()
    
    init(window: UIWindow, managedObjectContext: NSManagedObjectContext) {
        self.window = window
        self.managedObjectContext = managedObjectContext
        super.init()
        self.window.rootViewController = self.rootViewController
        self.window.makeKeyAndVisible()
    }
    
    // MARK: - Coordinator
    func start() {
        self.tabBarController.viewControllers = [ArticlesCoordinator(managedObjectContext: self.managedObjectContext), BookmarksCoordinator(managedObjectContext: self.managedObjectContext), DevotionsCoordinator(), PodcastsCoordinator()].map({(coord: Coordinator) -> UIViewController in
            coord.start()
            self.addChildCoordinator(childCoordinator: coord)
            return coord.rootViewController
        })
    }
}
