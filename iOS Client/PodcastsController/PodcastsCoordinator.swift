//
//  PodcastsCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import ReSwift

class PodcastsCoordinator: Coordinator, StoreSubscriber {
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return navigationController
    }
    var route: [RouteComponent] = []
    
    var tab: Tab = .podcasts
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    func start() {
        let podcastsController = MBPodcastsViewController.instantiateFromStoryboard()
        navigationController.pushViewController(podcastsController, animated: true)
        route = [.base]
        if let persistentContainer = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
            MBStore().syncPodcasts(persistentContainer: persistentContainer) { (isNewData: Bool?, syncErr: Error?) in
                if syncErr == nil {
                    let podcasts = MBStore().getPodcasts(persistentContainer: persistentContainer)
                    DispatchQueue.main.async {
                        MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: podcasts)))
                    }
                }
            }
        }
        
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        guard state.navigationState.selectedTab == .podcasts, let newRoute = state.navigationState.routes[.podcasts] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
}
