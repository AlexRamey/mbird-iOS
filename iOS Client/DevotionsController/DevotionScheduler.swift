//
//  DevotionScheduler.swift
//  iOS Client
//
//  Created by Alex Ramey on 5/17/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import UserNotifications

enum NotificationPermission {
    case allowed, denied, error
}

protocol DevotionScheduler {
    func cancelNotifications()
    func promptForNotifications(withDevotions devotions: [LoadedDevotion], atHour hour: Int, minute: Int, completion: @escaping (NotificationPermission) -> Void)
}

class Scheduler: DevotionScheduler {
    let center = UNUserNotificationCenter.current()
    
    func cancelNotifications() {
        self.center.removeAllPendingNotificationRequests()
    }
    
    func promptForNotifications(withDevotions devotions: [LoadedDevotion], atHour hour: Int, minute: Int, completion: @escaping (NotificationPermission) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.scheduleNotifications(withCenter: self.center, forDevotions: devotions, atHour: hour, minute: minute)
                completion(.allowed)
            } else if error != nil {
                completion(.error)
            } else {
                completion(.denied)
            }
        }
    }
    
    private func scheduleNotifications(withCenter center: UNUserNotificationCenter, forDevotions devotions: [LoadedDevotion], atHour hour: Int, minute: Int) {
        
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
            
            if let dateComponents = devotion.dateComponentsForNotification(hour: hour, minute: minute) {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let content = DevotionNotificationContent(devotion: devotion)
                let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
                center.add(request)
            }
            
            i = (i + 1) % sortedDevotions.count
        }
    }
}

extension Date {
    static let ddMMFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()
    
    func toMMddString() -> String {
        return Date.ddMMFormatter.string(from: self)
    }
}
