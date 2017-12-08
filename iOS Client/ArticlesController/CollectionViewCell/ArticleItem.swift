//
//  ArticleItem.swift
//  iOS Client
//
//  Created by Alex Ramey on 12/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

class ArticleItem: UICollectionViewCell {
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    let client = MBClient()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(article: MBArticle) {
        self.client.getImageData(imageID: Int(article.imageID)) { image in
            if image != nil {
                DispatchQueue.main.async {
                    self.coverImage.image = image
                }
            }
        }
        
        self.coverImage.image = nil
        titleLabel.attributedText = article.title?.convertHtml()
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textColor = UIColor.ArticleTitle
        titleLabel.sizeToFit()
    }
    
}
