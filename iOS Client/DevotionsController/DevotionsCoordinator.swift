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
    let scheduler: DevotionScheduler = Scheduler()
    
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
                        self.scheduleDevotionsIfNecessary(devotions: newDevotions)
                    }
                }
            }
        } else {
            MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: devotions)))
            self.scheduleDevotionsIfNecessary(devotions: devotions)
        }
    }
    
    private func scheduleDevotionsIfNecessary(devotions: [LoadedDevotion]) {
        guard let min = UserDefaults.standard.value(forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY) as? Int else {
            return // user hasn't set up daily reminders
        }
        
        self.scheduler.promptForNotifications(withDevotions: devotions, atHour: min/60, minute: min%60) { permission in
            DispatchQueue.main.async {
                switch permission {
                case .allowed:
                    print("success!")
                default:
                    print("unable to schedule notifications")
                }
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
