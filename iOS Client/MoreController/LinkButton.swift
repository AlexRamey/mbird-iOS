//
//  LinkButton.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/5/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class LinkButton: UIButton {
    var link: URL?
    
    func configure(title: String, link: URL) {
        let attributedTitle = NSMutableAttributedString(string: title,
                                                        attributes: [NSAttributedString.Key.font: UIFont(name: "IowanOldStyle-Bold", size: 20)!,
                                                                     NSAttributedString.Key.foregroundColor: UIColor.white])
        self.setAttributedTitle(attributedTitle, for: .normal)
        self.link = link
        self.backgroundColor = UIColor.MBSalmon
        self.layer.cornerRadius = 5
    }
}
