//
//  TableViewHeaderView.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/9/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class SectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var sectionTitle: UILabel!
    @IBOutlet weak var searchGlass: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.sectionTitle.backgroundColor = UIColor.white
        self.sectionTitle.textColor = UIColor.MBOrange
        self.sectionTitle.font = UIFont(name: "AvenirNext-Bold", size: 18.0)
        self.sectionTitle.textAlignment = .center
    }
    
    func setText(_ text: String) {
        self.sectionTitle.text = "\u{00B7}\u{00B7}\u{00B7}   \(text.uppercased())   \u{00B7}\u{00B7}\u{00B7}"
    }
    
    func setSearchVisible(isVisible: Bool) {
        self.searchGlass.isHidden = !isVisible
        self.searchGlass.isEnabled = isVisible
    }
    
    @IBAction func searchArticles(_ sender: UIButton) {
        MBStore.sharedStore.dispatch(SearchArticles())
    }
}
