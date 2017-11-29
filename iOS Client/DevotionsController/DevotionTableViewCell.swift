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
    
    
    func configure(day: String, month: String, verse: String, read: Bool) {
        dayLabel.text = day
        monthLabel.text = month
        verseLabel.text = verse
        
        readNotifier.layer.cornerRadius = readNotifier.bounds.width / 2
        readNotifier.backgroundColor = read ? .clear : UIColor.ArticleTitle
    }
    
}
