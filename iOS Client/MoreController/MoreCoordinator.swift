//
//  MoreCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/5/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class MoreCoordinator: Coordinator, MoreHandler {
    var childCoordinators: [Coordinator] = []
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    func start() {
        let moreViewController = MoreViewController.instantiateFromStoryboard(handler: self)
        navigationController.pushViewController(moreViewController, animated: true)
    }
    
    func openLink(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
