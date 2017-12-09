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
    var articleID: Int32 = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(article: MBArticle) {
        self.articleID = article.articleID
        self.coverImage.image = nil
        
        titleLabel.attributedText = article.title?.convertHtml()
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textColor = UIColor.ArticleTitle
        titleLabel.sizeToFit()
        
        if let savedData = article.image?.image {
            self.coverImage.image = UIImage(data: savedData as Data)
        } else if article.imageID != 0 {
            self.client.getImageData(imageID: Int(article.imageID)) { data in
                DispatchQueue.main.async {
                    if let imageData = data, self.articleID == article.articleID, article.image?.image == nil {
                        self.coverImage.image = UIImage(data: imageData)
                        if let context = article.managedObjectContext {
                            do {
                                let imageObject = ArticlePicture(context: context)
                                imageObject.image = imageData as NSData
                                article.image = imageObject
                                try context.save()
                            } catch {
                                print("unable to save image data for \(article.articleID)")
                            }
                        }
                    }
                }
            }
        }
    }
    
}
