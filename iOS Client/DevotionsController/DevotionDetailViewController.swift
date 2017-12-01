//
//  DevotionDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/15/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class DevotionDetailViewController: UIViewController, StoreSubscriber {

    @IBOutlet weak var contentLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }

    func newState(state: MBAppState) {
        if let devotion = state.devotionState.selectedDevotion {
            contentLabel.text = devotion.text
        }
    }
    
    static func instantiateFromStoryboard() -> DevotionDetailViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DevotionDetailViewController") as! DevotionDetailViewController
        // swiftlint:enable force_cast
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToDevotions(sender:)))
    }
    
    @objc func backToDevotions(sender: UIBarButtonItem) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    

}
