//
//  ArticleCollectionViewCell.swift
//  iOS Client
//
//  Created by Witten, Jonathan (Synchrony, consultant) on 3/10/19.
//  Copyright © 2019 Mockingbird. All rights reserved.
//

import UIKit

class RecentArticleCollectionViewCell: UICollectionViewCell, ThumbnailImageCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnailImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbnailImage.contentMode = .scaleAspectFill
        self.thumbnailImage.clipsToBounds = true
        self.thumbnailImage.layer.cornerRadius = 5
        
        self.categoryLabel.textColor = UIColor.MBOrange
        self.categoryLabel.font = UIFont(name: "AvenirNext-Bold", size: 13.0)
        
        self.dateLabel.textColor = UIColor.lightGray
        self.dateLabel.font = UIFont(name: "AvenirNext-Bold", size: 13.0)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.MBSelectedCell
        self.selectedBackgroundView = bgColorView
    }
    
    func configure(title: NSAttributedString, category: String, date: Date?) {
        self.titleLabel.attributedText = title
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 22.0)
        self.titleLabel.sizeToFit()
        self.categoryLabel.text = category.uppercased()
        if let date = date {
            // show the date
            var longDate = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
            if let idx = longDate.index(of: ",") {
                longDate = String(longDate.prefix(upTo: idx))
            }
            self.dateLabel.text = longDate
        } else {
            self.dateLabel.text = "recent"
        }
    }

}
