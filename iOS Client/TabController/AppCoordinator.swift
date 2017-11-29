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

class AppCoordinator: NSObject, Coordinator, UITabBarControllerDelegate, StoreSubscriber, UNUserNotificationCenterDelegate {
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
                MBStore().syncDevotions { devotions, error in
                    if error != nil {
                        print("Could not sync devotions and schedule devotions")
                        print(error)
                    } else if devotions != nil {
                        center.delegate = self
                        self.scheduleNotifications(devotions: devotions!.map{$0.devotion})
                    }
                }
            } else {
                print(error)
            }
        }
    }
    
    func scheduleNotifications(devotions: [MBDevotion]) {
        print("scheduling notifications")
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        devotions.forEach { devotion in
            guard let devotionDay = Formatters.devotionDateFormatter.date(from: devotion.date), let calendar = Formatters.calendar else {
                return
            }
            var dateComponents = DateComponents()
            dateComponents.hour = 10
            dateComponents.minute = 30
            dateComponents.year = calendar.component(NSCalendar.Unit.year, from: devotionDay)
            dateComponents.month = calendar.component(NSCalendar.Unit.month, from: devotionDay)
            dateComponents.day = calendar.component(NSCalendar.Unit.day, from: devotionDay)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = devotion.verse
            content.body = "Read your daily devotion from Mockingbird"
            content.sound = UNNotificationSound.default()
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
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
    
    // MARK: - UNNotificationDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        MBStore().syncDevotions { devotions, error in
            if error != nil {
                print("Could not load devotion from notifications")
            } else {
                let date = Date()
                if let devotion = devotions?.first(where: { Formatters.devotionDateFormatter.date(from: $0.devotion.date) == date}) {
                    MBStore.sharedStore.dispatch(DevotionNotification(devotion: devotion.devotion))
                }
                MBStore.sharedStore.dispatch(LoadedDevotions(devotions: .loaded(data: devotions ?? [])))
            }
        }
    }
}
