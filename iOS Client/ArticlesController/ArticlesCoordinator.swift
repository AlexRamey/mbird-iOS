//
//  ArticlesCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import ReSwift

class ArticlesCoordinator: NSObject, Coordinator, StoreSubscriber, UINavigationControllerDelegate {
    var route: [Route] = [.base]
    
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    // MARK: - showTimestamps() is used for debug purposes
    @objc func showTimestamps() {
        let lastOverallUpdate = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_ARTICLE_UPDATE_TIMESTAMP)
        let lastBackgroundUpdate = UserDefaults.standard.double(forKey: MBConstants.DEFAULTS_KEY_BACKGROUND_APP_REFRESH_TIMESTAMP)
        
        let lastOverallUpdateDate = Date(timeIntervalSinceReferenceDate: lastOverallUpdate)
        let lastBackgroundUpdateDate = Date(timeIntervalSinceReferenceDate: lastBackgroundUpdate)
        
        let dateFormatter = DateFormatter()
        if let timeZone = TimeZone(identifier: "America/New_York") {
            dateFormatter.timeZone = timeZone
        }
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let msg = "Last Update: \(dateFormatter.string(from: lastOverallUpdateDate))\nLast Background Refresh: \(dateFormatter.string(from: lastBackgroundUpdateDate))"
        
        let ac = UIAlertController(title: "DEBUG", message: msg, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "👍", style: .default, handler: nil))
        self.navigationController.present(ac, animated: true, completion: nil)
    }
    
    // MARK: - Coordinator
    func start() {
        let articlesController = MBArticlesViewController.instantiateFromStoryboard()
        
        // TODO: Remove this block
        let item = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(ArticlesCoordinator.showTimestamps))
        articlesController.navigationItem.setRightBarButton(item, animated: false)
        // END TODO
        
        self.navigationController.pushViewController(articlesController, animated: true)
        MBStore.sharedStore.subscribe(self)
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        guard state.navigationState.selectedTab == .articles, let newRoute = state.navigationState.routes[.articles] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
}
