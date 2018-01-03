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
import AVKit

class PodcastsCoordinator: Coordinator, StoreSubscriber {
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return navigationController
    }
    var route: [RouteComponent] = []
    
    var tab: Tab = .podcasts
    
    let podcastsStore = MBPodcastsStore()
    
    var player = AVPlayer()
    var currentPlayingPodcast: MBPodcast?
    var playerState: PlayerState = .initialized
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    func start() {
        let podcastsController = MBPodcastsViewController.instantiateFromStoryboard()
        navigationController.pushViewController(podcastsController, animated: true)
        route = [.base]
        MBStore.sharedStore.subscribe(self)
        podcastsStore.syncPodcasts { (podcasts: [MBPodcast]?, syncErr: Error?) in
            if syncErr == nil, let pods = podcasts {
                DispatchQueue.main.async {
                    MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: pods)))
                }
            }
        }
        
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        
        switch state.podcastsState.player {
        case .initialized:
            break
        case .playing:
            if let podcast = state.podcastsState.selectedPodcast, podcast.guid != currentPlayingPodcast?.guid {
                start(podcast)
                currentPlayingPodcast = state.podcastsState.selectedPodcast
            } else if case .paused = playerState {
                player.play()
            }
        case .paused:
            player.pause()
        case .error:
            break
        }
        
        playerState = state.podcastsState.player
        
        guard state.navigationState.selectedTab == .podcasts, let newRoute = state.navigationState.routes[.podcasts] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
    }
    
    func start(_ podcast: MBPodcast) {
        if let guid = podcast.guid,
        let url = URL(string:guid) {
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            player.play()
        }
    }
}

enum PlayerState {
    case initialized
    case playing
    case paused
    case error
}
