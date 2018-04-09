//
//  CategoryHeaderTableViewCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/7/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class CategoryHeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.black
        self.categoryLabel.textColor = UIColor.MBBlue
        self.categoryLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .heavy)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCategory(cat: String?) {
        self.categoryLabel.text = cat
    }
    
}
