//
//  ArticleItem.swift
//  iOS Client
//
//  Created by Alex Ramey on 12/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import Nuke

class ArticleItem: UICollectionViewCell {
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    let client = MBClient()
    var articleID: Int32 = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.coverImage.contentMode = .scaleAspectFill
        self.coverImage.clipsToBounds = true
    }
    
    func configure(article: MBArticle) {
        self.articleID = article.articleID
        
        titleLabel.attributedText = article.title?.convertHtml()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = UIColor.MBOrange
        titleLabel.sizeToFit()
        
        self.coverImage.image = nil
        
        if let savedData = article.image?.image {
            self.coverImage.image = UIImage(data: savedData as Data)
        } else if let imageLink = article.imageLink, let url = URL(string: imageLink) {
            Manager.shared.loadImage(with: url, into: self.coverImage)
        } else if article.imageID != 0 {
            self.client.getImageURL(imageID: Int(article.imageID)) { imageURL in
                DispatchQueue.main.async {
                    if let url = imageURL, let context = article.managedObjectContext {
                        do {
                            article.imageLink = url
                            try context.save()
                        } catch {
                            print("😅 unable to save image url for \(article.articleID)")
                        }
                    }
                    if self.articleID == article.articleID, let imageLink = imageURL, let imageURL = URL(string: imageLink) {
                        Manager.shared.loadImage(with: imageURL, into: self.coverImage)
                    }
                }
            }
        }
    }
    
}
