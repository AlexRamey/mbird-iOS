//
//  BookmarksCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import ReSwift

class BookmarksCoordinator: NSObject, Coordinator, StoreSubscriber {
    var childCoordinators: [Coordinator] = []
    var route: [RouteComponent] = [.base]
    var tab: Tab = .bookmarks
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    // MARK: - Coordinator
    func start() {
        let bookmarksController = MBArticlesViewController.instantiateFromStoryboard(bookmarks: true)
        self.navigationController.pushViewController(bookmarksController, animated: true)
        MBStore.sharedStore.subscribe(self)
    }
    
    // MARK: - StoreSubscriber
    
    func newState(state: MBAppState){
        guard state.navigationState.selectedTab == .bookmarks, let newRoute = state.navigationState.routes[.bookmarks] else{
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
}
