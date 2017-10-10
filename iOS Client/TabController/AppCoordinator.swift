//
//  AppCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import ReSwift

class AppCoordinator: NSObject, Coordinator, UITabBarControllerDelegate, StoreSubscriber {
    var route: [Route] = [Route]()
    
    var childCoordinators: [Coordinator] = []
    var selectedTab: Tab?
    
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
        MBStore.sharedStore.subscribe(self)
        self.tabBarController.viewControllers = [ArticlesCoordinator(), BookmarksCoordinator()].map({(coord: Coordinator) -> UIViewController in
            coord.start()
            self.addChildCoordinator(childCoordinator: coord)
            return coord.rootViewController
        })
    }
    
    // MARK: - StoreSubscriber
    
    func newState(state: MBAppState) {
        if state.navigationState.selectedTab != selectedTab, let rootVC = rootViewController as? MBTabBarController {
            rootVC.select(tab: state.navigationState.selectedTab)
            selectedTab = state.navigationState.selectedTab
        }
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        if let navController = viewController as? UINavigationController, let newTab = Tab.tab(forViewController: navController.viewControllers[0]) {
            // Send off the Action
            MBStore.sharedStore.dispatch(NavigationActionSwitchTab(tab: newTab))
        }
        
        return false
    }
}
