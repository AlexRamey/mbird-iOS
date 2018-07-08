//
//  CategoryArticleTableViewCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/7/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class CategoryArticleTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbnailImage.contentMode = .scaleAspectFill
        self.thumbnailImage.clipsToBounds = true
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.MBSelectedCell
        self.selectedBackgroundView = bgColorView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setTitle(_ title: NSAttributedString?) {
        self.titleLabel.attributedText = title
        self.titleLabel.textColor = UIColor.black
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 22.0)
        self.titleLabel.sizeToFit()
    }
}
