//
//  ScheduleDailyDevotionViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 5/14/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import UserNotifications

enum NotificationPermission {
    case allowed, denied, error
}

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
            statusLabel.text = "Scheduled for \(minutesToTimeString(min: val))"
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
        sender.isEnabled = false
        let components = NSCalendar.current.dateComponents(Set<Calendar.Component>([.hour, .minute]), from: self.timePicker.date)
        
        if let hour = components.hour, let minute = components.minute {
            self.promptForNotifications(withDevotions: self.devotions, atHour: hour, minute: minute) { permission in
                DispatchQueue.main.async {
                    switch permission {
                    case .allowed:
                        self.cancelButton.isEnabled = true
                        let totalMin = hour * 60 + minute
                        UserDefaults.standard.set(totalMin, forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY)
                        self.statusLabel.text = "Scheduled for \(self.minutesToTimeString(min: totalMin))"
                    case .denied:
                        self.promptForSettings()
                    case .error:
                        self.errorAlert()
                    }
                    sender.isEnabled = true
                }
            }
        } else {
            sender.isEnabled = true
        }
    }

    private func promptForSettings() {
        let settingsButton = NSLocalizedString("Settings", comment: "")
        let cancelButton = NSLocalizedString("Cancel", comment: "")
        let message = NSLocalizedString("Please give Mockingbird permission to alert you with daily devotionals by updating your notification settings.", comment: "")
        let goToSettingsAlert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        goToSettingsAlert.addAction(UIAlertAction(title: settingsButton, style: .destructive, handler: { (action: UIAlertAction) in
            DispatchQueue.main.async {
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl)
                    } else {
                        UIApplication.shared.openURL(settingsUrl as URL)
                    }
                }
            }
        }))
        
        goToSettingsAlert.addAction(UIAlertAction(title: cancelButton, style: .cancel, handler: nil))
        self.present(goToSettingsAlert, animated: true, completion: nil)
    }
    
    private func errorAlert() {
        let message = "An unexpected error occurred. Unable to schedule daily notifications."
        let alert = UIAlertController(title: "Done", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
