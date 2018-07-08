//
//  MBDevotionsViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import CVCalendar

class MBDevotionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendarView: CVCalendarView!
    
    let devotionsStore = MBDevotionsStore()
    var devotions: [LoadedDevotion] = []
    var cellReusableId: String = "DevotionTableViewCell"
    var latestSelectedDate: CVDate?
    weak var delegate: DevotionTableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(UINib(nibName: cellReusableId, bundle: nil), forCellReuseIdentifier: cellReusableId)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(selectToday(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "schedule"), style: .plain, target: self, action: #selector(self.scheduleNotifications(sender:)))
        
        monthLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 24.0)
        menuView.delegate = self
        calendarView.delegate = self
        calendarView.calendarAppearanceDelegate = self
        
        self.loadDevotions()
    }
    
    private func loadDevotions() {
        self.devotions = devotionsStore.getDevotions()
        
        if self.devotions.count > 0 {
            self.tableView.reloadData()
            return
        }
        
        devotionsStore.syncDevotions { syncedDevotions, error in
            DispatchQueue.main.async {
                if error != nil {
                    print("error syncing devotions: \(String(describing: error?.localizedDescription))")
                } else if let newDevotions = syncedDevotions {
                    self.devotions = newDevotions
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func scheduleNotifications(sender: UIBarButtonItem) {
        let vc = ScheduleDailyDevotionViewController.instantiateFromStoryboard()
        vc.modalPresentationStyle = .popover
        let dim = self.view.bounds.width * 0.75
        vc.preferredContentSize = CGSize(width: dim, height: dim)
        vc.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        vc.popoverPresentationController?.delegate = self
        self.present(vc, animated: true) {}
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        menuView.commitMenuViewUpdate()
        calendarView.commitCalendarViewUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToSelectedDevotion(animated: false)
    }
    
    @objc private func selectToday(_ sender: Any) {
        self.calendarView.toggleCurrentDayView()
    }
    
    static func instantiateFromStoryboard() -> MBDevotionsViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DevotionsViewController") as! MBDevotionsViewController
        // swiftlint:enable force_cast
        vc.tabBarItem = UITabBarItem(title: "Devotions", image: UIImage(named: "bible-gray"), selectedImage: UIImage(named: "bible-selected"))
        return vc
    }
    
    func scrollToSelectedDevotion(animated: Bool) {
        guard let selectedRow = devotions.index(where: { (devotion) -> Bool in
            if let selectedDate = self.latestSelectedDate?.convertedDate(),
                selectedDate.toMMddString() == devotion.dateAsMMdd {
                return true
            }
            
            return false
        }) else {
            return
        }
        
        tableView.scrollToRow(at: IndexPath(row: selectedRow, section: 0), at: .top, animated: animated)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let devotion = devotions[indexPath.row]
        //swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReusableId) as! DevotionTableViewCell
        //swiftlint:enable force_cast
        cell.configure(devotion: devotion)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devotions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let selectedDate = devotions[indexPath.row].dateInCurrentYear {
            calendarView.toggleViewWithDate(selectedDate)
        }
        
        if let delegate = self.delegate {
            // mark devotion as read
            devotions[indexPath.row].read = true
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            // persist that it has been read
            let devotion = devotions[indexPath.row]
            try? self.devotionsStore.replace(devotion: devotion)
            
            // show detail view controller
            delegate.selectedDevotion(devotion)
        }
    }
}

extension MBDevotionsViewController: CVCalendarViewDelegate, CVCalendarMenuViewDelegate, CVCalendarViewAppearanceDelegate {
    func presentationMode() -> CalendarMode {
        return CalendarMode.monthView
    }
    
    func firstWeekday() -> Weekday {
        return Weekday.monday
    }
    
    func didSelectDayView(_ dayView: DayView, animationDidFinish: Bool) {
        self.latestSelectedDate = dayView.date
        self.scrollToSelectedDevotion(animated: true)
        let monthIndex = dayView.date.month - 1
        guard monthIndex < Calendar.current.monthSymbols.count else {
            return
        }
        let month = Calendar.current.monthSymbols[monthIndex]
        self.monthLabel.text = month
        
    }
    
    // MARK: - CVCalendarViewAppearanceDelegate
    func dayLabelPresentWeekdayHighlightedBackgroundColor() -> UIColor {
        return UIColor.MBOrange
    }
    
    func dayLabelPresentWeekdayHighlightedBackgroundAlpha() -> CGFloat {
        return 1.0
    }
    
    func dayLabelFont(by weekDay: Weekday, status: CVStatus, present: CVPresent) -> UIFont {
        return UIFont(name: "IowanOldStyle-Roman", size: 14) ?? UIFont.systemFont(ofSize: 14)
    }
    
    func dayLabelWeekdaySelectedBackgroundColor() -> UIColor {
        return UIColor.MBOrange.withAlphaComponent(0.75)
    }
    
    func dayOfWeekFont() -> UIFont {
        return UIFont(name: "IowanOldStyle-Roman", size: 12) ?? UIFont.systemFont(ofSize: 12)
    }
}

extension MBDevotionsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.permittedArrowDirections = .any
    }
}

protocol DevotionTableViewDelegate: class {
    func selectedDevotion(_ devotion: LoadedDevotion)
}
