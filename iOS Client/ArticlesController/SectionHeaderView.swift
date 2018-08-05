//
//  TableViewHeaderView.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/9/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class SectionHeaderView: UITableViewHeaderFooterView, SearchBarHolder {
    @IBOutlet weak var sectionTitle: UILabel!
    @IBOutlet weak var searchGlass: UIButton!
    weak var delegate: HeaderViewDelegate?
    weak var searchBar: UISearchBar?
    
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
    
    @IBAction func searchArticles(_ sender: UIButton) {
        guard let delegate = self.delegate else {
            return
        }
        
        if let searchBar = delegate.searchTapped(sender: self) {
            searchBar.frame = CGRect(x: self.frame.width, y: 0.0, width: searchBar.bounds.width, height: searchBar.bounds.height)
            self.addSubview(searchBar)
            UIView.animate(withDuration: 0.5, animations: {
                // reveal the search bar
                searchBar.frame = CGRect(x: 0.0, y: 0.0, width: searchBar.bounds.width, height: searchBar.bounds.height)
            }) { (_) in
                searchBar.becomeFirstResponder()
            }
            self.searchBar = searchBar
        }
    }
    
    @IBAction func filterCategory(_ sender: UIButton) {
        delegate?.filterTapped(sender: self)
    }
    
    // MARK: SearchBarHolder
    func removeSearchBar() {
        self.searchBar?.removeFromSuperview()
    }
}

protocol HeaderViewDelegate: class {
    func searchTapped(sender: SectionHeaderView) -> UISearchBar?
    func filterTapped(sender: SectionHeaderView)
}
