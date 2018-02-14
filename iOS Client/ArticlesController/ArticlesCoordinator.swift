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
import SafariServices
import CoreData

class ArticlesCoordinator: NSObject, Coordinator, StoreSubscriber, UINavigationControllerDelegate, SafariDisplayer, SFSafariViewControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var route: [RouteComponent] = [.base]
    var tab: Tab = .articles
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
        let articlesController = MBArticlesViewController.instantiateFromStoryboard()
        articlesController.managedObjectContext = self.managedObjectContext
        self.navigationController.pushViewController(articlesController, animated: true)
        MBStore.sharedStore.subscribe(self)
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        guard state.navigationState.selectedTab == .articles,
            let newRoute = state.navigationState.routes[.articles] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
        
        self.displaySafariVC(forURL: state.navigationState.safariOverlays[.articles].flatMap {return $0}, withDelegate: self)
    }
    
    // MARK: - SafariViewControllerDelegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        MBStore.sharedStore.dispatch(SelectedArticleLink(url: nil))
    }
}
