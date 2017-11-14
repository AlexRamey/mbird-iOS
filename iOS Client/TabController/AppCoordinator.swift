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
import UserNotifications

class AppCoordinator: NSObject, Coordinator, UITabBarControllerDelegate, StoreSubscriber {
    var route: [RouteComponent] = [RouteComponent]()
    
    var childCoordinators: [Coordinator] = []
    var tab: Tab = .articles
    
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
        self.tabBarController.viewControllers = [ArticlesCoordinator(), BookmarksCoordinator(), DevotionsCoordinator()].map({(coord: Coordinator) -> UIViewController in
            coord.start()
            self.addChildCoordinator(childCoordinator: coord)
            return coord.rootViewController
        })
        promptForNotifications()
    }
    
    func promptForNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                self.scheduleNotifications()
            } else {
                print(error)
            }
        }
    }
    
    func scheduleNotifications() {
        var dateComponents = DateComponents()
        dateComponents.hour = 11
        dateComponents.minute = 0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Title goes here"
        content.body = "Main text goes here"
        content.categoryIdentifier = "customIdentifier"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default()
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request)
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        if self.tab != state.navigationState.selectedTab, let rootVC = rootViewController as? MBTabBarController {
            self.tab = state.navigationState.selectedTab
            rootVC.select(tab: self.tab)
        }
    }
    
    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let tabViewControllers = tabBarController.viewControllers,
           let newTab = Tab(rawValue: tabViewControllers.index(of: viewController) ?? -1) {
                MBStore.sharedStore.dispatch(NavigationActionSwitchTab(tab: newTab))
        }
        
        return false
    }
}
