//
//  MBDevotionsViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class MBDevotionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let devotionsStore = MBDevotionsStore()
    var devotions: [LoadedDevotion] = []
    var cellReusableId: String = "DevotionTableViewCell"
    weak var delegate: DevotionTableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\u{00B7}\u{00B7}\u{00B7}   DEVOTIONS   \u{00B7}\u{00B7}\u{00B7}"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Devotions", style: .plain, target: nil, action: nil)
        self.tabBarItem.title = "Devotions"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(UINib(nibName: cellReusableId, bundle: nil), forCellReuseIdentifier: cellReusableId)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(selectToday(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "schedule"), style: .plain, target: self, action: #selector(self.scheduleNotifications(sender:)))
        
        monthLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 24.0)
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
        let viewController = ScheduleDailyDevotionViewController.instantiateFromStoryboard()
        viewController.modalPresentationStyle = .popover
        let dim = self.view.bounds.width * 0.75
        viewController.preferredContentSize = CGSize(width: dim, height: dim)
        viewController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        viewController.popoverPresentationController?.delegate = self
        self.present(viewController, animated: true) {}
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToSelectedDevotion(animated: false)
    }
    
    @objc private func selectToday(_ sender: Any) {
        self.scrollToSelectedDevotion(animated: true)
    }
    
    static func instantiateFromStoryboard() -> MBDevotionsViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DevotionsViewController") as! MBDevotionsViewController
        // swiftlint:enable force_cast
        viewController.tabBarItem = UITabBarItem(title: "Devotions", image: UIImage(named: "bible-gray"), selectedImage: UIImage(named: "bible-selected"))
        return viewController
    }
    
    func scrollToSelectedDevotion(animated: Bool) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let today = dateFormatter.string(from: Date())
        
        guard let selectedRow = devotions.index(where: { (devotion) -> Bool in
            return devotion.dateAsMMdd == today
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
