//
//  BookmarkCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 1/30/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import CoreData

class BookmarkCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    var objectId: NSManagedObjectID?
    var lastOperation: Operation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
    }
    
    // MARK: - View Life Cycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        lastOperation?.cancel()
        titleLabel.text = nil
        coverImageView.image = nil
    }
    
    func configure(article: MBArticle, withQueue queue: OperationQueue) {
        self.titleLabel.attributedText = article.title?.convertHtml()
        self.objectId = article.objectID
        self.titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        self.titleLabel.textColor = UIColor.MBOrange
        self.titleLabel.sizeToFit()

        let imageMaker = ImageMakerOperation(article: article)
        imageMaker.completionBlock = {
            if imageMaker.isCancelled {
                return
            }
            DispatchQueue.main.async {
                if self.objectId != article.objectID {
                    return
                }

                self.coverImageView.image = article.uiimage
            }
        }
        queue.addOperation(imageMaker)
        lastOperation = imageMaker
    }
}
