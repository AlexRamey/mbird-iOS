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

class PodcastsCoordinator: NSObject, Coordinator, StoreSubscriber, AVAudioPlayerDelegate {
    
    var childCoordinators: [Coordinator] = []
    weak var playerDelegate: PodcastPlayerDelegate?
    
    var rootViewController: UIViewController {
        return navigationController
    }
    var route: [RouteComponent] = []
    
    var tab: Tab = .podcasts
    
    let podcastsStore = MBPodcastsStore()
    
    var player = AVPlayer()
    var currentPlayingPodcast: MBPodcast?
    var playerState: PlayerState = .initialized
    var lastSeek: Double = 0.0
    var timer: Timer?
    
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
    
    @objc func updateDuration(_ sender: Timer) {
        if let totalDuration = player.currentItem?.duration.seconds {
            playerDelegate?.updateCurrentDuration(current: getCurrentDuration(), total: totalDuration)
        }
    }
    
    // MARK: - StoreSubscriber
    func newState(state: MBAppState) {
        // Handle changes in the player state
        switch state.podcastsState.player {
        case .initialized:
            break
        case .playing:
            if let podcast = state.podcastsState.selectedPodcast, podcast.guid != currentPlayingPodcast?.guid, let guid = podcast.guid {
                startPlaying(guid)
                currentPlayingPodcast = state.podcastsState.selectedPodcast
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDuration(_:)), userInfo: nil, repeats: true)

            } else if case .paused = playerState {
                player.play()
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDuration(_:)), userInfo: nil, repeats: true)
            }
        case .paused:
            player.pause()
            timer?.invalidate()
        case .error, .finished:
            timer?.invalidate()
            break
        }
        playerState = state.podcastsState.player
        
        if lastSeek != state.podcastsState.lastSeek {
            let time = CMTime(seconds: state.podcastsState.lastSeek, preferredTimescale: 1)
            player.seek(to: time)
        }
        lastSeek = state.podcastsState.lastSeek
        
        // Handle changes in navigation state
        guard state.navigationState.selectedTab == .podcasts, let newRoute = state.navigationState.routes[.podcasts] else {
            return
        }
        build(newRoute: newRoute)
        route = newRoute
        if let lastRoute = newRoute.last,
            case .detail(_) = lastRoute,
            let podcastDetail = navigationController.viewControllers.last as? PodcastDetailViewController {
            playerDelegate = podcastDetail
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
}

