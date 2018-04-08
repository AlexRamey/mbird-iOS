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
    var articleID: Int32 = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.thumbnailImage.contentMode = .scaleAspectFill
        self.thumbnailImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
