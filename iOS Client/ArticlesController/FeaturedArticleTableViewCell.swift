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
    var articleID: Int32 = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.featuredImage.contentMode = .scaleAspectFill
        self.featuredImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
