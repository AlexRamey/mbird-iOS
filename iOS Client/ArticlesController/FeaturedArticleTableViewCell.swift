//
//  FeaturedArticleCellTableViewCell.swift
//  
//
//  Created by Alex Ramey on 4/7/18.
//

import UIKit

class FeaturedArticleTableViewCell: UITableViewCell {
    @IBOutlet weak var featuredImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.featuredImage.contentMode = .scaleAspectFill
        self.featuredImage.clipsToBounds = true
        
        self.categoryLabel.textColor = UIColor.black
        self.categoryLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        
        self.timeLabel.textColor = UIColor.black
        self.timeLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .semibold)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setTitle(_ title: NSAttributedString?) {
        self.titleLabel.attributedText = title
        self.titleLabel.textColor = UIColor.MBOrange
        self.titleLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .heavy)
        self.titleLabel.sizeToFit()
    }
    
    func setCategory(_ cat: String?) {
        self.categoryLabel.text = cat ?? "mockingbird"
    }
    
    func setDate(date: Date?) {
        if let date = date {
            if date.timeIntervalSinceNow > -16 * 3600 {
                // just show time if it was published recently
                self.timeLabel.text = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            } else {
                // just show date otherwise
                var longDate = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
                if let idx = longDate.index(of: ",") {
                    longDate = String(longDate.prefix(upTo: idx))
                }
                self.timeLabel.text = longDate
            }
        } else {
            self.timeLabel.text = "recent"
        }
    }
}
