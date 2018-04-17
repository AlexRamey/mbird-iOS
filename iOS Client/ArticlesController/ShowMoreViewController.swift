//
//  ShowMoreViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/16/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class ShowMoreViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = ArticleState
    
    static func instantiateFromStoryboard() -> ShowMoreViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShowMoreViewController") as! ShowMoreViewController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MBStore.sharedStore.subscribe(self) {
            $0.select { appState in
                appState.articleState
            }.skipRepeats { lhs, rhs in
                lhs.selectedCategory == rhs.selectedCategory
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MBStore.sharedStore.unsubscribe(self)
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToArticles(sender:)))
    }
    
    @objc func backToArticles(sender: AnyObject) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    
    func newState(state: ArticleState) {
        print("new article state😁! \(state.selectedCategory)")
    }
}
