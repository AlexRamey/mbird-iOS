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
    
    var stream: PodcastStream?
    
    func configure(image: UIImage? = nil, stream: PodcastStream, on: Bool = false) {
        toggleSwitch.isOn = on
        titleLabel.text = stream.title
        podcastImage.image = image
        self.stream = stream
        podcastImage.layer.cornerRadius = 10
        self.selectionStyle = .none
    }
    @IBAction func toggled(_ sender: UISwitch) {
        guard let stream = stream else {
            return
        }
        MBStore.sharedStore.dispatch(TogglePodcastFilter(podcastStream: stream))
    }
    
}
