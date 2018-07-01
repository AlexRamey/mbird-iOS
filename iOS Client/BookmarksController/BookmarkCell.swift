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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
    }
    
    // MARK: - View Life Cycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        coverImageView.image = nil
    }
    
    func configure(article: MBArticle) {
        self.titleLabel.attributedText = article.title?.convertHtml()
        self.titleLabel.textColor = UIColor.MBOrange
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 16.0)
        self.titleLabel.sizeToFit()
    }
}
