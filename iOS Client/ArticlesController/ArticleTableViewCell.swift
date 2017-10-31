//
//  ArticleTableViewCell.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/29/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class ArticleTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    private var isInitialized: Bool = false
    var titleAttrString: NSAttributedString?
    var authorAttrString: NSAttributedString?
    var indexPath: IndexPath?
    var delegate: HTMLCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(title: String?, author: String?, indexPath: IndexPath ) {
        self.indexPath = indexPath
        if isInitialized {
            titleLabel.attributedText = self.titleAttrString
            authorLabel.attributedText = self.authorAttrString
        } else {
            DispatchQueue.global(qos: .background).async {
                self.titleAttrString = title?.convertHtml()
                self.authorAttrString = author?.convertHtml()
                DispatchQueue.main.async {
                    self.isInitialized = true
                    self.delegate?.cellDoneRenderingHTML(cell: self)
                }
            }
        }

    }
    
}
