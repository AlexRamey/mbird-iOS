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

class ArticlesCoordinator: NSObject, Coordinator, StoreSubscriber, UINavigationControllerDelegate, SFSafariViewControllerDelegate {
    var childCoordinators: [Coordinator] = []
    var route: [RouteComponent] = [.base]
    var tab: Tab = .articles
    var overlay: URL? = nil
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    // MARK: - Coordinator
    func start() {
        let articlesController = MBArticlesViewController.instantiateFromStoryboard(bookmarks: false)
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
        
        let articlesSafariOverlay: URL? = state.navigationState.safariOverlays[.articles]!
        if self.overlay == nil, let overlay = articlesSafariOverlay {
            self.overlay = overlay
            let overlayVC = SFSafariViewController(url: overlay)
            overlayVC.delegate = self
            self.navigationController.present(overlayVC, animated: true, completion: nil)
        } else if self.overlay != nil, articlesSafariOverlay == nil {
            self.overlay = nil
            self.navigationController.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - SafariViewControllerDelegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        MBStore.sharedStore.dispatch(SelectedArticleLink(url: nil))
        self.overlay = nil
    }
}
