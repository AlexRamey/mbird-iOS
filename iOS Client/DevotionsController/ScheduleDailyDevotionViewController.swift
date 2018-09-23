//
//  ScheduleDailyDevotionViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 5/14/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class ScheduleDailyDevotionViewController: UIViewController {
    @IBOutlet weak var timePicker: UIDatePicker!
    var devotionsStore = MBDevotionsStore()
    var devotions: [LoadedDevotion] = []
    let defaultTimeInMinutes = 60 * 8 // 8 a.m.
    let scheduler: DevotionScheduler = Scheduler()
    
    static func instantiateFromStoryboard() -> ScheduleDailyDevotionViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScheduleDailyDevotionVC") as! ScheduleDailyDevotionViewController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Daily Devotional"
        self.devotions = self.devotionsStore.getDevotions()
        
        // configure timePicker
        self.timePicker.datePickerMode = .time
        self.timePicker.minuteInterval = 15
        
        // set initial time to the user's current setting
        var currentSetting: Int = defaultTimeInMinutes
        if let val = UserDefaults.standard.value(forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY) as? Int {
            currentSetting = val
        }
        
        rollPickerToTime(totalMinutes: currentSetting)
    }
    
    private func rollPickerToTime(totalMinutes: Int) {
        var components = DateComponents()
        components.hour = totalMinutes / 60
        components.minute = totalMinutes % 60
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
    
    @IBAction func scheduleNotifications(sender: UIButton) {
        sender.isEnabled = false
        let components = NSCalendar.current.dateComponents(Set<Calendar.Component>([.hour, .minute]), from: self.timePicker.date)
        
        if let hour = components.hour, let minute = components.minute {
            self.scheduler.promptForNotifications(withDevotions: self.devotions, atHour: hour, minute: minute) { permission in
                DispatchQueue.main.async {
                    switch permission {
                    case .allowed:
                        let totalMin = hour * 60 + minute
                        UserDefaults.standard.set(totalMin, forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY)
                        self.dismiss(animated: true, completion: nil)
                        return
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
    
    @IBAction func cancelNotifications(sender: UIButton) {
        sender.isEnabled = false
        self.scheduler.cancelNotifications()
        UserDefaults.standard.removeObject(forKey: MBConstants.DEFAULTS_DAILY_DEVOTION_TIME_KEY)
        rollPickerToTime(totalMinutes: defaultTimeInMinutes)
        self.cancelAlert()
        sender.isEnabled = true
    }

    private func promptForSettings() {
        let settingsButton = NSLocalizedString("Settings", comment: "")
        let cancelButton = NSLocalizedString("Cancel", comment: "")
        let message = NSLocalizedString("Please give Mockingbird permission to alert you with daily devotionals by updating your notification settings.", comment: "")
        let goToSettingsAlert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        goToSettingsAlert.addAction(UIAlertAction(title: settingsButton, style: .destructive, handler: { (_: UIAlertAction) in
            DispatchQueue.main.async {
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl)
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

    private func cancelAlert() {
        let message = "Disabled daily notifications."
        let alert = UIAlertController(title: "Done", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
