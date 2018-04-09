//
//  RecentArticleTableViewCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/7/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class RecentArticleTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbnailImage.contentMode = .scaleAspectFill
        self.thumbnailImage.clipsToBounds = true
        
        self.categoryLabel.textColor = UIColor.black
        self.categoryLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCategory(_ cat: String?) {
        self.categoryLabel.text = cat ?? "mockingbird"
    }
    
    func setTitle(_ title: NSAttributedString?) {
        self.titleLabel.attributedText = title
        self.titleLabel.textColor = UIColor.MBOrange
        self.titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        self.titleLabel.sizeToFit()
    }
    
}
