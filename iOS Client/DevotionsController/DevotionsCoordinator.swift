//
//  DevotionsCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
import Foundation
import UIKit
import ReSwift
import UserNotifications

class DevotionsCoordinator: NSObject, Coordinator, StoreSubscriber, UNUserNotificationCenterDelegate {
    var route: [RouteComponent] = [.base]
    var tab: Tab = .devotions
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    func start() {
        let devotionsController = MBDevotionsViewController.instantiateFromStoryboard()
        navigationController.pushViewController(devotionsController, animated: true)
        MBStore.sharedStore.subscribe(self)
        
        MBStore().syncDevotions { devotions, error in
            if error != nil {
                MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.error))
            } else if let devotions = devotions {
                MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: devotions)))
            }
        }
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
            guard let dateComponents = devotion.dateComponentsForNotification else {
                return
            }
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let content = DevotionNotificationContent(devotion: devotion)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        guard state.navigationState.selectedTab == .devotions, let newRoute = state.navigationState.routes[.devotions] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
    
    // MARK: - UNNotificationDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        MBStore().syncDevotions { devotions, error in
            if error != nil {
                print("Could not load devotion from notifications")
            } else {
                let date = Date()
                if let devotion = devotions?.first(where: { Formatters.devotionDateFormatter.date(from: $0.devotion.date) == date}) {
                    MBStore.sharedStore.dispatch(DevotionNotification(devotion: devotion))
                }
                MBStore.sharedStore.dispatch(LoadedDevotions(devotions: .loaded(data: devotions ?? [])))
            }
        }
    }
}
