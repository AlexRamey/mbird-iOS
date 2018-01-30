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
        UNUserNotificationCenter.current().delegate = self
        let devotions = devotionsStore.getDevotions()
        if devotions.count == 0 {
            devotionsStore.syncDevotions { syncedDevotions, error in
                DispatchQueue.main.async {
                    if error != nil {
                        MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.error))
                    } else if let newDevotions = syncedDevotions {
                        MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: newDevotions)))
                        self.promptForNotifications(withDevotions: newDevotions)
                    }
                }
            }
        } else {
            MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: devotions)))
            self.promptForNotifications(withDevotions: devotions)
        }
    }
    
    func promptForNotifications(withDevotions devotions: [LoadedDevotion]) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                self.scheduleNotifications(withCenter: center, forDevotions: devotions)
            } else {
                print(error)
            }
        }
    }
    
    func scheduleNotifications(withCenter center: UNUserNotificationCenter, forDevotions devotions: [LoadedDevotion]) {
        print("scheduling notifications")

        center.getPendingNotificationRequests { (requests) in
            let startDate = Date().toMMddString()
            let sortedDevotions = devotions.sorted {$0.date < $1.date}
            guard let startIndex = (sortedDevotions.index { $0.dateAsMMdd == startDate }) else {
                return
            }
            
            var i = startIndex
            var outstandingNotifications: Int = 0
            
            while outstandingNotifications < MBConstants.DEVOTION_NOTIFICATION_WINDOW_SIZE {
                outstandingNotifications += 1
                
                let devotion = sortedDevotions[i]
                let notificationId = "daily-devotion-\(devotion.dateAsMMdd)"
                
                if let dateComponents = devotion.dateComponentsForNotification,
                    !requests.contains(where: {$0.identifier == notificationId}) {
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let content = DevotionNotificationContent(devotion: devotion)
                    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
                    center.add(request)
                }
                
                i = (i + 1) % sortedDevotions.count
            }
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
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            selectTodaysDevotion()
        } else {
            // user dismissed notification
        }
        
        // notify the system that we're done
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    private func selectTodaysDevotion() {
        let devotions = devotionsStore.getDevotions()
        MBStore.sharedStore.dispatch(LoadedDevotions(devotions: .loaded(data: devotions)))
        
        if let devotion = devotions.first(where: {$0.dateAsMMdd == Date().toMMddString()}) {
            MBStore.sharedStore.dispatch(SelectedDevotion(devotion: devotion))
        }
    }
}

extension Date
{
    func toMMddString() -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        return dateFormatter.string(from: self)
    }
}
