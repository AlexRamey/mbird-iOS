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
    var articleDAO: ArticleDAO
    let window: UIWindow
    let managedObjectContext: NSManagedObjectContext
    let podcastsStore = MBPodcastsStore()
    
    private lazy var player: PodcastPlayer = {
        return PodcastPlayer(repository: podcastsStore)
    }()
    
    private lazy var tabBarController: MBTabBarController = {
        let tabBarController = MBTabBarController.instantiateFromStoryboard(player: self.player)
        return tabBarController
    }()
    
    init(window: UIWindow, dao: ArticleDAO, managedObjectContext: NSManagedObjectContext) {
        self.window = window
        self.managedObjectContext = managedObjectContext
        self.articleDAO = dao
        super.init()
        self.window.rootViewController = self.rootViewController
        self.window.makeKeyAndVisible()
    }
    
    // MARK: - Coordinator
    func start() {
        self.tabBarController.viewControllers = [ArticlesCoordinator(dao: self.articleDAO), BookmarksCoordinator(dao: self.articleDAO, managedObjectContext: self.managedObjectContext), DevotionsCoordinator(), PodcastsCoordinator(store: self.podcastsStore, player: self.player)].map({(coord: Coordinator) -> UIViewController in
            coord.start()
            self.addChildCoordinator(childCoordinator: coord)
            return coord.rootViewController
        })
    }
}
