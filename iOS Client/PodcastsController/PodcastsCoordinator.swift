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

class PodcastsCoordinator: NSObject, Coordinator, StoreSubscriber, AVAudioPlayerDelegate, PodcastDetailViewControllerDelegate, PodcastTableViewDelegate {
    var articleDAO: ArticleDAO?
    var childCoordinators: [Coordinator] = []
    var podcastDetailViewController: PodcastDetailViewController? {
        return navigationController.viewControllers.last as? PodcastDetailViewController
    }
    weak var delegate: PodcastTableViewDelegate?
    
    var rootViewController: UIViewController {
        return navigationController
    }
    
    let podcastsStore = MBPodcastsStore()
    
    var player = AVPlayer()
    var currentPlayingPodcast: Podcast?
    var timer: Timer?
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(delegate: PodcastTableViewDelegate?){
        self.delegate = delegate
        super.init()
    }
    
    func start() {
        let podcastsController = MBPodcastsViewController.instantiateFromStoryboard()
        podcastsController.delegate = self
        navigationController.pushViewController(podcastsController, animated: true)
        
        self.configureRemoteCommandHandling()
        MBStore.sharedStore.subscribe(self)
        let saved = podcastsStore.getSavedPodcastsTitles()
        MBStore.sharedStore.dispatch(SetDownloadedPodcasts(titles: saved))
        _ = firstly { () -> Promise<[Podcast]> in
            podcastsStore.getSavedPodcasts()
        }.then { podcasts -> Promise<[Podcast]> in
            DispatchQueue.main.async {
                MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: podcasts)))
            }
            return self.podcastsStore.syncPodcasts()
        }.then { podcasts -> Void in
            DispatchQueue.main.async {
                MBStore.sharedStore.dispatch(LoadedPodcasts(podcasts: .loaded(data: podcasts)))
            }
        }.always { () -> Void in
            self.podcastsStore.readPodcastFilterSettings()
        }.catch { error in
            print("error fetching podcasts: \(error)")
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
            break
        case .paused, .error, .finished:
            timer?.invalidate()
            player.pause()
            self.setAudioSessionIsActive(false)
        }
    }
    
    func getCurrentDuration() -> Double {
        let time = player.currentTime()
        return time.seconds
    }
    
    private func playPodcast(_ podcast: Podcast) {
        if let guid = podcast.guid {
            // Play if stored to disk, else fetch from network
            if currentPlayingPodcast?.guid != guid,
                podcastsStore.conatainsSavedPodcast(podcast),
                let url = podcastsStore.getUrlFor(podcast: podcast) {
                let item = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: item)
            } else if currentPlayingPodcast?.guid != guid,
                let guid = podcast.guid,
                let url = URL(string: guid) {
                let item = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: item)
            }
            self.setAudioSessionIsActive(true)
            player.play()
            self.configureNowPlayingInfo(podcast: podcast)
            currentPlayingPodcast = podcast
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDuration(_:)), userInfo: nil, repeats: true)
        }
    }
    
    // MARK: - PodcastDetailViewControllerDelegate
    func seek(to second: Double) {
        let time = CMTime(seconds: second, preferredTimescale: 1)
        player.seek(to: time)
    }
    
    // MARK: - PodcastTableViewDelegate
    func didSelectPodcast(_ podcast: Podcast) {
        self.playPodcast(podcast)
        if let delegate = self.delegate {
            self.delegate?.didSelectPodcast(podcast)
        }
        let detailViewController = PodcastDetailViewController.instantiateFromStoryboard(podcast: podcast)
        detailViewController.delegate = self
        self.navigationController.pushViewController(detailViewController, animated: true)
    }
    
    func filterPodcasts() {
        let filterViewController = PodcastsFilterViewController.instantiateFromStoryboard()
        self.navigationController.pushViewController(filterViewController, animated: true)
    }
}
