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
    var devotionsStore = MBDevotionsStore()
    
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
        let devotions = devotionsStore.getDevotions()
        if devotions.count == 0 {
            devotionsStore.syncDevotions { syncedDevotions, error in
                DispatchQueue.main.async {
                    if error != nil {
                        MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.error))
                    } else if let newDevotions = syncedDevotions {
                        MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: newDevotions)))
                        self.promptForNotifications()
                    }
                }
            }
        } else {
            MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: devotions)))
            self.promptForNotifications()
        }
    }
    
    func promptForNotifications() {
        let scheduled = UserDefaults().bool(forKey: "scheduledNotifications")
        if !scheduled{
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    let devotions = self.devotionsStore.getDevotions()
                    self.scheduleNotifications(devotions: devotions)
                    UserDefaults().set(true, forKey: "scheduledNotifications")
                } else {
                    print(error)
                }
            }
        }
    }
    
    func scheduleNotifications(devotions: [LoadedDevotion]) {
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
        let devotions = devotionsStore.getDevotions()
        let date = Date()
        if let devotion = devotions.first(where: { $0.date == LoadedDevotion.devotionDateFormatter.string(from: date) }) {
            MBStore.sharedStore.dispatch(SelectedDevotion(devotion: devotion))
        }
        MBStore.sharedStore.dispatch(LoadedDevotions(devotions: .loaded(data: devotions)))
    }
}
