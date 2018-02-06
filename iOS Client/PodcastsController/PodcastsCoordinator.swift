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
import PromiseKit

class PodcastsCoordinator: NSObject, Coordinator, StoreSubscriber, AVAudioPlayerDelegate, PodcastDetailViewControllerDelegate {
    
    var childCoordinators: [Coordinator] = []
    var podcastDetailViewController: PodcastDetailViewController? {
        return navigationController.viewControllers.last as? PodcastDetailViewController
    }
    
    var rootViewController: UIViewController {
        return navigationController
    }
    var route: [RouteComponent] = []
    
    var tab: Tab = .podcasts
    
    let podcastsStore = MBPodcastsStore()
    
    var player = AVPlayer()
    var currentPlayingPodcast: Podcast?
    var timer: Timer?
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    func start() {
        let podcastsController = MBPodcastsViewController.instantiateFromStoryboard()
        navigationController.pushViewController(podcastsController, animated: true)
        route = [.base]
        MBStore.sharedStore.subscribe(self)
        
        _ = firstly {
            podcastsStore.syncPodcasts()
        }.then { podcasts -> Void in
            DispatchQueue.main.async {
                MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: podcasts)))
            }
        }.catch{ error in
            print("error fetching podcasts: \(error)")
            DispatchQueue.main.async {
                MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .error))
            }
        }
    }
    
    @objc func updateDuration(_ sender: Timer) {
        if let totalDuration = player.currentItem?.duration.seconds {
            podcastDetailViewController?.updateCurrentDuration(current: getCurrentDuration(), total: totalDuration)
        }
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        // Handle changes in the player state
        switch state.podcastsState.player {
        case .initialized:
            break
        case .playing:
            if let podcast = state.podcastsState.selectedPodcast, let guid = podcast.guid, let url = URL(string: guid) {
                if currentPlayingPodcast?.guid != guid {
                    let item = AVPlayerItem(url: url)
                    player.replaceCurrentItem(with: item)
                }
                player.play()
                currentPlayingPodcast = state.podcastsState.selectedPodcast
                timer?.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDuration(_:)), userInfo: nil, repeats: true)
                print("playing podcast")
            }
        case .paused:
            player.pause()
            timer?.invalidate()
        case .error, .finished:
            timer?.invalidate()
            break
        }
        
        // Handle changes in navigation state
        guard state.navigationState.selectedTab == .podcasts, let newRoute = state.navigationState.routes[.podcasts] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
        if let podcastDetailVC = navigationController.viewControllers.last as? PodcastDetailViewController {
            podcastDetailVC.delegate = self
        }
    }
    
    func startPlaying(_ guid: String) {
        if let url = URL(string: guid) {
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            player.play()
        }
    }
    
    func getCurrentDuration() -> Double {
        let time = player.currentTime()
        return time.seconds
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            MBStore.sharedStore.dispatch(FinishedPodcast())
        } else {
            MBStore.sharedStore.dispatch(PodcastError())
        }
    }
    
    func seek(to second: Double) {
        let time = CMTime(seconds: second, preferredTimescale: 1)
        player.seek(to: time)
    }
}

protocol PodcastDetailViewControllerDelegate {
    func seek(to second: Double)
}
