//
//  PodcastInfoTableViewCell.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/4/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class PodcastInfoTableViewCell: UITableViewCell {


    @IBOutlet weak var podcastName: UILabel!
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 18)
        self.podcastName.font = UIFont(name: "IowanOldStyle-Roman", size: 14)
        self.podcastName.textColor = UIColor.gray
        self.selectionStyle = .none
    }
    
    func configure(image: UIImage, name: String, description: String) {
        self.titleLabel.text = description
        self.podcastImage.image = image
        self.podcastName.text = name
    }
}
