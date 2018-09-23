//
//  MoreViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/5/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

protocol MoreHandler {
    func openLink(_ url: URL)
}

class MoreViewController: UIViewController {

    @IBOutlet weak var supportButton: LinkButton!
    @IBOutlet weak var magazineButton: LinkButton!
    @IBOutlet weak var conferencesButton: LinkButton!
    @IBOutlet weak var aboutButton: LinkButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    var handler: MoreHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topTitleLabel.font = UIFont(name: "IowanOldStyle-Roman",
                                    size: 20)
        quoteLabel.font =  UIFont(name: "IowanOldStyle-Italic",
                                  size: 14)
        addressLabel.font =  UIFont(name: "IowanOldStyle-Roman",
                                    size: 12)
        supportButton.configure(title: "SUPPORT",
                                link: URL(string: "http://www.mbird.com/support/donate/")!,
                                onButtonPress: pressedLink)
        magazineButton.configure(title: "MAGAZINE",
                                 link: URL(string: "http://magazine.mbird.com/")!,
                                 onButtonPress: pressedLink)
        conferencesButton.configure(title: "CONFERENCES",
                                    link: URL(string: "http://conference.mbird.com/")!,
                                    onButtonPress: pressedLink)
        aboutButton.configure(title: "ABOUT",
                              link: URL(string: "http://www.mbird.com/about/history-and-mission/")!,
                              onButtonPress: pressedLink)
        self.title = "\u{00B7}\u{00B7}\u{00B7}   MORE   \u{00B7}\u{00B7}\u{00B7}"
        self.tabBarItem.title = "More"
        
    }
    
    static func instantiateFromStoryboard(handler: MoreHandler) -> MoreViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MoreViewController") as! MoreViewController
        // swiftlint:enable force_cast
        viewController.tabBarItem = UITabBarItem(title: "More", image: UIImage(named: "more"), selectedImage: UIImage(named: "more"))
        viewController.handler = handler
        return viewController
    }
    
    func pressedLink(_ button: LinkButton) {
        guard let url = button.link else {
            return
        }
        handler?.openLink(url)
    }
}
