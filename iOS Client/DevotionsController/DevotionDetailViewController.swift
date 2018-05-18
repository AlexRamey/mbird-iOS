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
    var selectedDevotion: LoadedDevotion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(self.shareDevotion(sender:)))
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
        if let devotion = state.devotionState.selectedDevotion {
            monthLabel.text = devotion.formattedMonth
            dayLabel.text = devotion.formattedMonthDay
            verseLabel.text = devotion.verse
            verseTextLabel.text = devotion.verseText
            bodyLabel.text = devotion.text
            self.selectedDevotion = devotion
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
    
    @objc func shareDevotion(sender: AnyObject) {
        guard let devotion = self.selectedDevotion else {
            return
        }
        
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: [ "Mockingbird Devotional: ", devotion.verse, devotion.verseText, devotion.text ], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [
            .airDrop,
            .assignToContact,
            .openInIBooks,
            .postToFlickr,
            .postToVimeo,
            .print,
            .saveToCameraRoll
        ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
