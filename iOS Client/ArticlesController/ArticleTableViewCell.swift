//
//  ArticleTableViewCell.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/29/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class ArticleTableViewCell: UITableViewCell {

    
    @IBOutlet weak var snippetLabel: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    var indexPath: IndexPath?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(title: NSAttributedString?, author: NSAttributedString?, snippet: String?, imageId: Int32?, client: MBClient, indexPath: IndexPath ) {
        self.indexPath = indexPath
        if let id = imageId {
            client.getImageData(imageID: Int(id)) { imageView in
                if imageView != nil {
                    DispatchQueue.main.async {
                        self.coverImage.image = imageView
                    }
                }
            }
        }
        titleLabel.attributedText = title
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textColor = UIColor.ArticleTitle
        authorLabel.attributedText = author
        authorLabel.font = UIFont.boldSystemFont(ofSize: 15)
        snippetLabel.text = snippet
    }
    
}
