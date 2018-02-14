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
import SafariServices

class BookmarksCoordinator: NSObject, Coordinator, StoreSubscriber, SafariDisplayer, SFSafariViewControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var route: [RouteComponent] = [.base]
    var tab: Tab = .bookmarks
    var overlay: URL?
    let managedObjectContext: NSManagedObjectContext
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    lazy var navigationController: UINavigationController = {
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
        
        self.displaySafariVC(forURL: state.navigationState.safariOverlays[.bookmarks].flatMap {return $0}, withDelegate: self)
    }
    
    // MARK: - SafariViewControllerDelegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        MBStore.sharedStore.dispatch(SelectedArticleLink(url: nil))
    }
}
