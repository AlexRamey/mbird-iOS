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
    var onButtonPress: ((LinkButton) -> Void)?
    
    func configure(title: String, link: URL, onButtonPress: @escaping ((LinkButton) -> Void)) {
        let attributedTitle = NSMutableAttributedString(string: title,
                                                        attributes: [NSAttributedStringKey.font: UIFont(name: "IowanOldStyle-Bold", size: 20)!,
                                                                     NSAttributedStringKey.foregroundColor: UIColor.white])
        self.setAttributedTitle(attributedTitle, for: .normal)
        self.link = link
        self.heightAnchor.constraint(equalToConstant: 36).isActive = true
        self.layer.cornerRadius = 5
        self.backgroundColor = UIColor.MBSalmon
        self.onButtonPress = onButtonPress
        self.addTarget(self, action: #selector(LinkButton.buttonPress), for: .touchUpInside)
        
    }
    
    @objc func buttonPress(_ button: LinkButton) {
        onButtonPress?(button)
    }
}
