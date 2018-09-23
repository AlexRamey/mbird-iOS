//
//  PodcastPlayer.swift
//  iOS Client
//
//  Created by Alex Ramey on 7/8/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import AVKit
import Foundation
import MediaPlayer

protocol PodcastPlayerSubscriber: class {
    func notify(currentProgress: Double, totalDuration: Double, isPlaying: Bool, isCanceled: Bool)
}

class PodcastPlayer: NSObject, AVAudioPlayerDelegate {
    var player = AVPlayer()
    var timer: Timer?
    var currentlyPlayingPodcast: Podcast?
    let repository: PodcastsRepository
    private var subscribers: [WeakRef<AnyObject>] = []
    var isCanceled = false
    
    init(repository: PodcastsRepository) {
        self.repository = repository
        super.init()
        self.configureRemoteCommandHandling()
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
            self.togglePlayPause()
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
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { (newSize) -> UIImage in
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
                let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                return newImage
            })
        }
        center.nowPlayingInfo = nowPlayingInfo
    }
    
    func getCurrentProgress() -> Double {
        let time = player.currentTime()
        return time.seconds.isNaN ? 0.0 : time.seconds
    }
    
    func getTotalDuration() -> Double {
        guard let totalDuration = player.currentItem?.duration.seconds, !totalDuration.isNaN else {
            return 0.0
        }
        return totalDuration
    }
    
    @objc func notifySubscribers() {
        self.subscribers.forEach { (subscriberRef) in
            if let subscriber = subscriberRef.value as? PodcastPlayerSubscriber {
                subscriber.notify(currentProgress: self.getCurrentProgress(), totalDuration: self.getTotalDuration(), isPlaying: self.player.rate != 0.0, isCanceled: self.isCanceled)
            }
        }
    }
    
    func subscribe(_ subscriber: PodcastPlayerSubscriber) {
        self.subscribers.append(WeakRef(value: subscriber))
    }
    
    func unsubscribe(_ unsubscriber: PodcastPlayerSubscriber) {
        if let index = self.subscribers.index(where: { (weakRef) -> Bool in
            if let subscriber = weakRef.value as? PodcastPlayerSubscriber {
                return subscriber === unsubscriber
            }
            return false
        }) {
            self.subscribers.remove(at: index)
        }
    }
    
    func playPodcast(_ podcast: Podcast) {
        if let guid = podcast.guid {
            
            // replace current player item if necessary
            if (currentlyPlayingPodcast?.guid ?? "no guid") != guid {
                var podcastURL: URL?
                
                if self.repository.containsSavedPodcast(podcast) {
                    podcastURL = self.repository.getUrlFor(podcast: podcast)
                } else {
                    podcastURL = URL(string: guid)
                }
                
                if let url = podcastURL {
                    let item = AVPlayerItem(url: url)
                    player.replaceCurrentItem(with: item)
                }
            }
            
            self.configureNowPlayingInfo(podcast: podcast)
            currentlyPlayingPodcast = podcast
            
            self.play()
        }
    }
    
    private func play() {
        self.isCanceled = false
        self.setAudioSessionIsActive(true)
        self.player.play()
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PodcastPlayer.notifySubscribers), userInfo: nil, repeats: true)
        self.notifySubscribers()
    }
    
    func pause() {
        timer?.invalidate()
        player.pause()
        self.notifySubscribers()
        self.setAudioSessionIsActive(false)
    }
    
    func stop() {
        timer?.invalidate()
        player.pause()
        self.isCanceled = true
        self.currentlyPlayingPodcast = nil
        self.notifySubscribers()
        self.setAudioSessionIsActive(false)
    }
    
    func togglePlayPause() {
        if self.player.rate == 0.0 {
            self.play()
        } else {
            self.pause()
        }
    }
    
    func seek(to second: Double) {
        let time = CMTime(seconds: second, preferredTimescale: 1)
        player.seek(to: time)
    }
}
