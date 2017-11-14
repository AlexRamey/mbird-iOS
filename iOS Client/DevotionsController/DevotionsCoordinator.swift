//
//  DevotionsCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
import Foundation
import UIKit
import ReSwift

class DevotionsCoordinator: NSObject, Coordinator, StoreSubscriber {
    var route: [RouteComponent] = [.base]
    var tab: Tab = .devotions
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    func start() {
        let devotionsController = MBDevotionsViewController.instantiateFromStoryboard()
        navigationController.pushViewController(devotionsController, animated: true)
        MBStore.sharedStore.subscribe(self)
        
        MBStore().syncDevotions { devotions, error in
            if error != nil {
                MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.error))
            } else if let devotions = devotions {
                MBStore.sharedStore.dispatch(LoadedDevotions(devotions: Loaded.loaded(data: devotions)))
            }
        }
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        guard state.navigationState.selectedTab == .devotions, let newRoute = state.navigationState.routes[.devotions] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
}
