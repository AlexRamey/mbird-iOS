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
import MediaPlayer
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
        self.configureRemoteCommandHandling()
        MBStore.sharedStore.subscribe(self)
        _ = firstly { () -> Promise<[Podcast]> in
            podcastsStore.getSavedPodcasts()
        }.then { podcasts -> Promise<[Podcast]> in
            DispatchQueue.main.async {
                MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: podcasts)))
            }
            return self.podcastsStore.syncPodcasts()
        }.then { podcasts -> Void in
            DispatchQueue.main.async {
                //MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: podcasts)))
            }
        }.always { () -> Void in
            self.podcastsStore.readPodcastFilterSettings()
        }.catch { error in
            print("error fetching podcasts: \(error)")
            DispatchQueue.main.async {
                MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .error))
            }
        }
    }
    
    private func setAudioSessionIsActive(_ active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            print("Activating Audio Session failed.")
        }
    }
    
    private func configureRemoteCommandHandling() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            MBStore.sharedStore.dispatch(PlayPausePodcast())
            return .success
        }
    }
    
    private func configureNowPlayingInfo(podcast: Podcast) {
        let center = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [
            MPMediaItemPropertyTitle: podcast.title ?? "Mbird Podcast",
            MPMediaItemPropertyArtist: podcast.author ?? "Mockingbird"
            ] as [String: Any]
        if let image = UIImage(named: podcast.image) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size , requestHandler: { (newSize) -> UIImage in
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
                let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                return newImage
            })
        }
        center.nowPlayingInfo = nowPlayingInfo
    }
    
    @objc func updateDuration(_ sender: Timer) {
        let current = getCurrentDuration()
        if let totalDuration = player.currentItem?.duration.seconds, !totalDuration.isNaN, !current.isNaN {
            podcastDetailViewController?.updateCurrentDuration(current: current, total: totalDuration)
        } else {
            podcastDetailViewController?.updateCurrentDuration(current: 0, total: 0)
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
                self.setAudioSessionIsActive(true)
                player.play()
                self.configureNowPlayingInfo(podcast: podcast)
                currentPlayingPodcast = state.podcastsState.selectedPodcast
                timer?.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDuration(_:)), userInfo: nil, repeats: true)
            }
        case .paused, .error, .finished:
            timer?.invalidate()
            player.pause()
            self.setAudioSessionIsActive(false)
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
    
    func getCurrentDuration() -> Double {
        let time = player.currentTime()
        return time.seconds
    }
    
    func seek(to second: Double) {
        let time = CMTime(seconds: second, preferredTimescale: 1)
        player.seek(to: time)
    }
}

protocol PodcastDetailViewControllerDelegate: class {
    func seek(to second: Double)
}
