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
    
    // MARK: - View Life Cycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        coverImageView.image = nil
    }
}
