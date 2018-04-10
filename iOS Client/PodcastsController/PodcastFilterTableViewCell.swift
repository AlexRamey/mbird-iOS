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
    
    var podcast: PodcastStream?
    
    static var reuseIdentifier: String = "PodcastFilterTableViewCell"
    func configure(image: UIImage? = nil, podcast: PodcastStream, on: Bool = false) {
        toggleSwitch.isOn = on
        titleLabel.text = podcast.title
        podcastImage.image = image
        self.podcast = podcast
        podcastImage.layer.cornerRadius = 10
        self.selectionStyle = .none
    }
    @IBAction func toggled(_ sender: UISwitch) {
        guard let podcast = podcast else {
            return
        }
        MBStore.sharedStore.dispatch(TogglePodcastFilter(podcastStream: podcast, visible: toggleSwitch.isOn))
    }
    
}
