//
//  RecentArticleTableViewCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/7/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class RecentArticleTableViewCell: UITableViewCell, ThumbnailImageCell {
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbnailImage.contentMode = .scaleAspectFill
        self.thumbnailImage.clipsToBounds = true
        
        self.categoryLabel.textColor = UIColor.MBOrange
        self.categoryLabel.font = UIFont(name: "AvenirNext-Bold", size: 13.0)
        
        self.timeLabel.textColor = UIColor.MBOrange
        self.timeLabel.font = UIFont(name: "AvenirNext-Bold", size: 13.0)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.MBSelectedCell
        self.selectedBackgroundView = bgColorView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCategory(_ cat: String?) {
        self.categoryLabel.text = (cat ?? "mockingbird").uppercased()
    }
    
    func setTitle(_ title: NSAttributedString?) {
        self.titleLabel.attributedText = title
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 22.0)
        self.titleLabel.sizeToFit()
    }
    
    func setDate(date: Date?) {
        if let date = date {
            // show the date
            var longDate = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
            if let idx = longDate.index(of: ",") {
                longDate = String(longDate.prefix(upTo: idx))
            }
            self.timeLabel.text = longDate
        } else {
            self.timeLabel.text = "recent"
        }
    }
}
