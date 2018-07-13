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
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var guid: String?
    var title: String?
    var saved: Bool = false
    weak var delegate: PodcastDownloadingDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.MBSelectedCell
        self.selectedBackgroundView = bgColorView
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 18)
        self.dateLabel.font = UIFont(name: "IowanOldStyle-Roman", size: 14)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(title: String,
                   image: UIImage?,
                   date: String?,
                   guid: String,
                   saved: Bool,
                   downloading: Bool) {
        activityIndicator.hidesWhenStopped = true
        titleLabel.text = title
        podcastImage.image = image
        podcastImage.layer.masksToBounds = true
        podcastImage.layer.cornerRadius = 5
        dateLabel.text = date
        self.guid = guid
        self.title = title
        downloading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        actionButton.isHidden = downloading ? true : false
        actionButton.setImage(saved ? UIImage(named: "download-done") : UIImage(named: "add"), for: .normal)
        self.saved = saved
    }
    
    @IBAction func pressActionButton(_ sender: Any) {
        if saved {
            removePodcast()
        } else {
            downloadPodcast()
        }
    }
    
    private func downloadPodcast() {
        guard let guid = self.guid, let title = title else {
            return
        }
        self.activityIndicator.startAnimating()
        self.actionButton.isHidden = true
        delegate?.downloadPodcast(url: guid, title: title)
    }
    
    private func removePodcast() {
        guard let title = title else {
            return
        }
        delegate?.removePodcast(title: title)
    }
}

protocol PodcastDownloadingDelegate: class {
    func downloadPodcast(url: String, title: String)
    func removePodcast(title: String)
}
