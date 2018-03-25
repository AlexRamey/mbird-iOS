//
//  BookmarkCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 1/30/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class BookmarkCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    
    
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
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        self.titleLabel.textColor = UIColor.MBOrange
        self.titleLabel.sizeToFit()
        
        if let savedData = article.image?.image {
            self.coverImageView.image = UIImage(data: savedData as Data)
        }
    }
}
