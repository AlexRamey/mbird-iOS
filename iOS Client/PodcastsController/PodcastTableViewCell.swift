//
//  PodcastTableViewCell.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {


    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var podcastImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var guid: String?
    var title: String?
    var delegate: PodcastDownloadingDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(title: String, image: UIImage?, date: String?, guid: String, saved: Bool, downloading: Bool) {
        activityIndicator.hidesWhenStopped = true
        titleLabel.text = title
        podcastImage.image = image
        podcastImage.layer.masksToBounds = true
        podcastImage.layer.cornerRadius = 5
        dateLabel.text = date
        self.guid = guid
        self.title = title
        if downloading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        addButton.isHidden = saved || downloading ? true : false
        
    }
    
    @IBAction func pressAddButton(_ sender: Any) {
        print("add button pressed")
        guard let guid = self.guid, let title = title else {
            return
        }
        delegate?.downloadPodcast(url: guid, title: title)
    }
}
