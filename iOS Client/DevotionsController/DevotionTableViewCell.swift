//
//  DevotionTableViewCell.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/22/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class DevotionTableViewCell: UITableViewCell {

    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var verseLabel: UILabel!
    @IBOutlet weak var readNotifier: UIImageView!
    
    
    func configure(devotion: LoadedDevotion) {
        dayLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 32)
        dayLabel.text = devotion.formattedMonthDay
        monthLabel.text = devotion.formattedMonth
        monthLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 16)
        verseLabel.text = devotion.verse
        verseLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 16)
        readNotifier.layer.cornerRadius = readNotifier.bounds.width / 2
        readNotifier.backgroundColor = devotion.read ? .clear : UIColor.MBOrange
    }
    
}
