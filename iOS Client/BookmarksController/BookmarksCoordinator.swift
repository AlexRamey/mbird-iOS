//
//  BookmarksCoordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import CoreData
import ReSwift

class BookmarksCoordinator: NSObject, Coordinator, StoreSubscriber {
    var childCoordinators: [Coordinator] = []
    var route: [RouteComponent] = [.base]
    var tab: Tab = .bookmarks
    let managedObjectContext: NSManagedObjectContext
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    // MARK: - Coordinator
    func start() {
        let bookmarksController = MBBookmarksViewController.instantiateFromStoryboard()
        bookmarksController.managedObjectContext = self.managedObjectContext
        self.navigationController.pushViewController(bookmarksController, animated: true)
        MBStore.sharedStore.subscribe(self)
    }
    
    // MARK: - StoreSubscriber
    
    func newState(state: MBAppState) {
        guard state.navigationState.selectedTab == .bookmarks, let newRoute = state.navigationState.routes[.bookmarks] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
}
