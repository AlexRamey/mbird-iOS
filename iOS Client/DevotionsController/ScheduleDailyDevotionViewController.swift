//
//  ScheduleDailyDevotionViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 5/14/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import UserNotifications

class ScheduleDailyDevotionViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    var devotionsStore = MBDevotionsStore()
    var devotions: [LoadedDevotion] = []
    let center = UNUserNotificationCenter.current()
    let defaultTimeInMinutes = 60 * 8 // 8 a.m.
    
    static func instantiateFromStoryboard() -> ScheduleDailyDevotionViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScheduleDailyDevotionVC") as! ScheduleDailyDevotionViewController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Daily Devotional"
        self.configureBackButton()
        self.devotions = self.devotionsStore.getDevotions()
        
        // configure timePicker
        self.timePicker.datePickerMode = .time
        self.timePicker.minuteInterval = 15
        
        // set initial time to the user's current setting
        var currentSetting: Int = defaultTimeInMinutes
        if let val = UserDefaults.standard.value(forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY) as? Int {
            currentSetting = val
            statusLabel.text = "Currently scheduled for \(minutesToTimeString(min: val))"
        } else {
            self.cancelButton.isEnabled = false
            statusLabel.text = "Schedule a time:"
        }
        
        var components = DateComponents()
        components.hour = currentSetting / 60
        components.minute = currentSetting % 60
        if let date = NSCalendar.current.date(from: components) {
            self.timePicker.setDate(date, animated: true)
        }
    }
    
    private func minutesToTimeString(min: Int) -> String {
        let hours = min / 60
        let minutes = String(format: "%02d", min % 60)
        
        if hours == 0 {
            return "12:\(minutes) A.M."
        } else if hours == 12 {
            return "\(hours):\(minutes) P.M."
        } else if hours > 12 {
            return "\(hours - 12):\(minutes) P.M."
        } else {
            return "\(hours):\(minutes) A.M."
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToDevotions(sender:)))
    }
    
    @objc func backToDevotions(sender: UIBarButtonItem) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    
    @IBAction func cancelNotifications(sender: UIBarButtonItem) {
        center.removeAllPendingNotificationRequests()
        // enter not-scheduled state
        cancelButton.isEnabled = false
        statusLabel.text = "Schedule a time:"
        UserDefaults.standard.removeObject(forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY)
    }
    
    @IBAction func scheduleNotifications(sender: UIBarButtonItem) {
        let components = NSCalendar.current.dateComponents(Set<Calendar.Component>([.hour, .minute]), from: self.timePicker.date)
        
        if let hour = components.hour, let minute = components.minute {
            self.promptForNotifications(withDevotions: self.devotions, atHour: hour, minute: minute)
            // todo: 1. add completion handlers to promptForNotification call chain
            // 2. prompt user to go to settings if they don't have permission
            // 3. report an error via alert if one occurs; update to new state only on success
            // 4. Create a lock so only one scheduling operation can occur at a time
            // enter scheduled state
            cancelButton.isEnabled = true
            let totalMin = hour * 60 + minute
            UserDefaults.standard.set(totalMin, forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY)
            statusLabel.text = "Currently scheduled for \(minutesToTimeString(min: totalMin))"
        }
    }
    
    func promptForNotifications(withDevotions devotions: [LoadedDevotion], atHour hour: Int, minute: Int) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                self.scheduleNotifications(withCenter: self.center, forDevotions: devotions, atHour: hour, minute: minute)
            } else {
                print(error as Any)
            }
        }
    }
    
    func scheduleNotifications(withCenter center: UNUserNotificationCenter, forDevotions devotions: [LoadedDevotion], atHour hour: Int, minute: Int) {
        print("scheduling notifications")
        
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
