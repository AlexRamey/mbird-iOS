//
//  PodcastFilterTableViewCell.swift
//  iOS Client
//
//  Created by Jonathan Witten on 4/9/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class PodcastFilterTableViewCell: UITableViewCell {
    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var podcastImage: UIImageView!
    weak var delegate: PodcastFilterDelegate?
    
    var filterOption: PodcastFilterOption?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 20)
         self.selectionStyle = .none
    }
    
    func configure(image: UIImage? = nil, title: String, option: PodcastFilterOption, isOn: Bool = false) {
        toggleSwitch.isOn = isOn
        titleLabel.text = title
        podcastImage.image = image
        self.filterOption = option
        podcastImage.layer.cornerRadius = 10
    }
    
    @IBAction func toggled(_ sender: UISwitch) {
        if let option = filterOption, let delegate = self.delegate {
            delegate.toggleFilterOption(option, isOn: sender.isOn)
        }
    }
}

protocol PodcastFilterDelegate: class {
    func toggleFilterOption(_ stream: PodcastFilterOption, isOn: Bool)
}
