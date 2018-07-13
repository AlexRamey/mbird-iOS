//
//  DevotionDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/15/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class DevotionDetailViewController: UIViewController {

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var verseLabel: UILabel!
    @IBOutlet weak var verseTextLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    var selectedDevotion: LoadedDevotion!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(self.shareDevotion(sender:)))
        monthLabel.text = selectedDevotion.formattedMonth
        dayLabel.text = selectedDevotion.formattedMonthDay
        verseLabel.text = selectedDevotion.verse
        verseTextLabel.text = selectedDevotion.verseText
        bodyLabel.text = selectedDevotion.text
        authorLabel.text = "- \(selectedDevotion.author)"
        monthLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 30)
        dayLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 25)
        verseLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 14)
        verseTextLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 16)
        bodyLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 16)
        authorLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 16)
    }
    
    static func instantiateFromStoryboard(devotion: LoadedDevotion) -> DevotionDetailViewController {
        // swiftlint:disable force_cast
        let devotionVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DevotionDetailViewController") as! DevotionDetailViewController
        // swiftlint:enable force_cast
        devotionVC.selectedDevotion = devotion
        return devotionVC
    }
    
    @objc func shareDevotion(sender: AnyObject) {
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: [ "Mockingbird Devotional: ", selectedDevotion.verse, selectedDevotion.verseText, selectedDevotion.text ], applicationActivities: nil)
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
