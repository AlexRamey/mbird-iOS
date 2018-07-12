//
//  DevotionsCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
import Foundation
import UIKit
import UserNotifications

class DevotionsCoordinator: NSObject, Coordinator, UNUserNotificationCenterDelegate, DevotionTableViewDelegate {
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
        devotionsController.delegate = self
        navigationController.pushViewController(devotionsController, animated: true)
        UNUserNotificationCenter.current().delegate = self
        let devotions = devotionsStore.getDevotions()
        self.scheduleDevotionsIfNecessary(devotions: devotions)
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
    
    private func showDevotionDetail(devotion: LoadedDevotion) {
        let detailVC = DevotionDetailViewController.instantiateFromStoryboard(devotion: devotion)
        self.navigationController.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - DevotionTableViewDelegate
    func selectedDevotion(_ devotion: LoadedDevotion) {
        self.showDevotionDetail(devotion: devotion)
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
        if let devotion = devotions.first(where: {$0.dateAsMMdd == Date().toMMddString()}) {
            self.navigationController.tabBarController?.selectedIndex = 2
            self.showDevotionDetail(devotion: devotion)
        }
    }
}
