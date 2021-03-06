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
    func notify(currentPodcastGuid: String?, currentProgress: Double, totalDuration: Double, isPlaying: Bool, isCanceled: Bool)
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioInterruption(_:)),
                                               name: NSNotification.Name.AVAudioSessionInterruption,
                                               object: nil)
    }
    
    @objc private func audioInterruption(_ notification: Notification) {
        // an interruption due to incoming phone call or alarm clock
        guard let userInfo = notification.userInfo,
            let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSessionInterruptionType(rawValue: interruptionTypeValue) else {
            return
        }
        
        switch interruptionType {
        case .began:
            // audio has already been interrupted (reflect in the UI)
            self.pause()
        case .ended:
            // interruption is over
            guard let interruptionOptionValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            
            let interruptionOption = AVAudioSessionInterruptionOptions(rawValue: interruptionOptionValue)
            if interruptionOption.contains(.shouldResume) {
                self.play()
            }
        }
    }
    
    private func setAudioSessionIsActive(_ active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            print("(de)activating Audio Session failed.")
        }
    }
    
    private func configureRemoteCommandHandling() {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            self.togglePlayPause()
            if let podcast = self.currentlyPlayingPodcast {
               self.configureNowPlayingInfo(podcast: podcast)
            }
            return .success
        }
        commandCenter.skipForwardCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.seek(relative: 15)
            return .success
        }
        commandCenter.skipBackwardCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.seek(relative: -15)
            return .success
        }
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
            if let position = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime {
                self.seek(to: position)
                return .success
            } else {
                return .commandFailed
            }
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
        if let currentItem = player.currentItem {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentItem.currentTime().seconds
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentItem.asset.duration.seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
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
                subscriber.notify(currentPodcastGuid: self.currentlyPlayingPodcast?.guid, currentProgress: self.getCurrentProgress(), totalDuration: self.getTotalDuration(), isPlaying: self.player.rate != 0.0, isCanceled: self.isCanceled)
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
    
    func playPodcast(_ podcast: Podcast, completion: @escaping () -> Void ) {
        guard let guid = podcast.guid else {
            completion()
            return
        }
        
        if (currentlyPlayingPodcast?.guid ?? "no guid") != guid {
            // new podcast; switch over to it
            self.stop()
            
            var podcastURL: URL?
            if self.repository.containsSavedPodcast(podcast) {
                podcastURL = self.repository.getUrlFor(podcast: podcast)
            } else {
                podcastURL = URL(string: guid)
            }
            
            guard let url = podcastURL else {
                completion()
                return
            }
            
            self.currentlyPlayingPodcast = podcast
            let asset = AVAsset(url: url)
            let keys: [String] = ["playable"]
            asset.loadValuesAsynchronously(forKeys: keys) {
                DispatchQueue.main.async {
                    guard let currentGuid = self.currentlyPlayingPodcast?.guid, currentGuid == guid else {
                        completion()
                        return
                    }
                    let item = AVPlayerItem(asset: asset)
                    self.player.replaceCurrentItem(with: item)
                    self.play()
                    self.configureNowPlayingInfo(podcast: podcast)
                    completion()
                }
            }
        } else {
            // same podcast; just resume it
            self.play()
            self.configureNowPlayingInfo(podcast: podcast)
            completion()
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
        let time = CMTime(seconds: second, preferredTimescale: 600)
        player.seek(to: time) { (_) in
            if let podcast = self.currentlyPlayingPodcast {
                self.configureNowPlayingInfo(podcast: podcast)
            }
        }
    }
    
    func seek(relative seconds: Double) {
        let currentTime = player.currentTime().seconds
        let newTime = currentTime + seconds
        seek(to: newTime)
    }
}
