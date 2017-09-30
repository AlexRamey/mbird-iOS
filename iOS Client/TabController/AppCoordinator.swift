//
//  AppCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

class AppCoordinator: NSObject, Coordinator, UITabBarControllerDelegate {
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return self.tabBarController
    }
    
    let window: UIWindow
    
    private lazy var tabBarController: MBTabBarController = {
        let tabBarController = MBTabBarController.instantiateFromStoryboard()
        tabBarController.delegate = self
        return tabBarController
    }()
    
    init(window: UIWindow) {
        self.window = window
        super.init()
        self.window.rootViewController = self.rootViewController
        self.window.makeKeyAndVisible()
    }
    
    // MARK: - Coordinator
    func start() {
        self.tabBarController.viewControllers = [ArticlesCoordinator(), BookmarksCoordinator()].map({(coord: Coordinator) -> UIViewController in
            coord.start()
            self.addChildCoordinator(childCoordinator: coord)
            return coord.rootViewController
        })
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        var selectedIndex = 0
        
        if let navController = viewController as? UINavigationController {
            if let title = navController.viewControllers[0].title {
                switch title {
                case "Articles":
                    selectedIndex = 0
                case "Bookmarks":
                    selectedIndex = 1
                default:
                    break
                }
            }
        }
        
        // Send off the Action
        MBStore.sharedStore.dispatch(NavigationActionSwitchTab(newIndex: selectedIndex))
        return false
    }
}
