//
//  MBTabBarController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift
import UIKit

class MBTabBarController: UITabBarController, StoreSubscriber {
    static func instantiateFromStoryboard() -> MBTabBarController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseTabController") as! MBTabBarController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MBStore.sharedStore.subscribe(self) {subscription in subscription.select {state in state}}
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        MBStore.sharedStore.unsubscribe(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - StoreSubscriber
    
    func newState(state: MBAppState) {
        if self.selectedIndex != state.navigationState.tabIndex {
            self.selectedIndex = state.navigationState.tabIndex
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
