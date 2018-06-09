//
//  MBDevotionsViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift
import CVCalendar

class MBDevotionsViewController: UIViewController, StoreSubscriber, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    
    let devotionsStore = MBDevotionsStore()
    var devotions: [LoadedDevotion] = []
    var cellReusableId: String = "DevotionTableViewCell"
    var latestSelectedDate: CVDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(selectToday(_:)))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "schedule"), style: .plain, target: self, action: #selector(self.scheduleNotifications(sender:)))
        
        tableView.register(UINib(nibName: cellReusableId, bundle: nil), forCellReuseIdentifier: cellReusableId)
        
        menuView.delegate = self
        calendarView.delegate = self
        calendarView.calendarAppearanceDelegate = self
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToSelectedDevotion(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
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
    
    func newState(state: MBAppState) {
        switch state.devotionState.devotions {
        case .error:
            break
        case .initial:
            break
        case .loading, .loadingFromDisk:
            break
        case .loaded(let loadedDevotions):
            if self.devotions.count != loadedDevotions.count {
                self.devotions = loadedDevotions
                tableView.reloadData()
            } else {
                var changedIndexPaths: [IndexPath] = []
                for (idx, loadedDevotion) in loadedDevotions.enumerated()
                    where self.devotions[idx] != loadedDevotion {
                    self.devotions[idx] = loadedDevotion
                    changedIndexPaths.append(IndexPath(row: idx, section: 0))
                }
                tableView.reloadRows(at: changedIndexPaths, with: .automatic)
            }
        }
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
        
        MBStore.sharedStore.dispatch(SelectedDevotion(devotion: devotions[indexPath.row]))
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
    }
    
    // MARK: - CVCalendarViewAppearanceDelegate
    func dayLabelPresentWeekdayHighlightedBackgroundColor() -> UIColor {
        return UIColor.MBOrange
    }
    
    func dayLabelPresentWeekdayHighlightedBackgroundAlpha() -> CGFloat {
        return 1.0
    }
}

extension MBDevotionsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func prepareForPopoverPresentation(popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.permittedArrowDirections = .any
    }
    
}
