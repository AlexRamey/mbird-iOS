//
//  DevotionDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/15/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class DevotionDetailViewController: UIViewController, StoreSubscriber {

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var verseLabel: UILabel!
    @IBOutlet weak var verseTextLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }

    func newState(state: MBAppState) {
        if let devotion = state.devotionState.selectedDevotion,
            let date = Formatters.devotionDateFormatter.date(from: devotion.date),
            let monthInt = Formatters.calendar?.component(.month, from: date),
            let day = Formatters.calendar?.component(.day, from: date) {
            monthLabel.text = Formatters.getMonth(fromInt: monthInt)
            dayLabel.text = String(describing: day)
            verseLabel.text = devotion.verse
            verseTextLabel.text = devotion.verseText
            bodyLabel.text = devotion.text
            
        }
    }
    
    static func instantiateFromStoryboard() -> DevotionDetailViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DevotionDetailViewController") as! DevotionDetailViewController
        // swiftlint:enable force_cast
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToDevotions(sender:)))
    }
    
    @objc func backToDevotions(sender: UIBarButtonItem) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    

}
