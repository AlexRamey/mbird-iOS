//
//  MBTabBarController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class MBTabBarController: UITabBarController, PodcastPlayerSubscriber {
    var playPauseView: PlayPauseView!
    var player: PodcastPlayer!
    var isCancelled: Bool = false
    
    static func instantiateFromStoryboard(player: PodcastPlayer) -> MBTabBarController {
        // swiftlint:disable force_cast
        let tabVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseTabController") as! MBTabBarController
        // swiftlint:enable force_cast
        tabVC.player = player
        return tabVC
    }
    
    func configurePlayPauseView() {
        let tabBar = self.tabBar
        playPauseView = PlayPauseView.loadInstance()
        playPauseView.translatesAutoresizingMaskIntoConstraints = false
        playPauseView.layer.masksToBounds = false
        playPauseView.clipsToBounds = false
        view.addSubview(playPauseView)
        playPauseView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playPauseView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playPauseView.bottomAnchor.constraint(equalTo: tabBar.topAnchor).isActive = true
        playPauseView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playPauseView.isHidden = true
        playPauseView.layer.shadowOffset = CGSize(width: 0, height: -10)
        playPauseView.layer.shadowRadius = 10
        playPauseView.layer.shadowOpacity = 0.2
        playPauseView.layer.shadowColor = UIColor.black.cgColor
        
        playPauseView.toggleButton.setImage(UIImage(named: "play-arrow"), for: .normal)
        playPauseView.toggleButton.addTarget(self, action: #selector(togglePlayPause(_:)), for: .touchUpInside)
        playPauseView.cancelButton.addTarget(self, action: #selector(cancelPodcast(_:)), for: .touchUpInside)
    }
    
    @objc func togglePlayPause(_ sender: UIButton) {
        self.player.togglePlayPause()
    }
    
    @objc func cancelPodcast(_ sender: UIButton) {
        self.isCancelled = true
        self.player.pause()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePlayPauseView()
        self.tabBar.tintColor = UIColor.MBSalmon
        self.player.subscribe(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Podcast Player Subscriber
    func notify(currentProgress: Double, totalDuration: Double, isPlaying: Bool) {
        var shouldShowPlayPause = true
        
        if !isPlaying && self.isCancelled {
            // this is the last notify we'll get before a podcast begins playing again
            shouldShowPlayPause = false
            self.isCancelled = false
        }
        
        if let podImageName = self.player.currentlyPlayingPodcast?.image {
            playPauseView.image.image = UIImage(named: podImageName)
        }
        playPauseView.titleLabel.text = self.player.currentlyPlayingPodcast?.title ?? "mbird podcast"
        
        if isPlaying {
            playPauseView.toggleButton.setImage(UIImage(named: "pause-bars"), for: .normal)
        } else {
            playPauseView.toggleButton.setImage(UIImage(named: "play-arrow"), for: .normal)
        }
        
        if self.selectedIndex == 3,
            let navigationController = self.viewControllers?.last as? UINavigationController,
            let _ = navigationController.topViewController as? PodcastDetailViewController {
            playPauseView?.isHidden = true
        } else {
            playPauseView?.isHidden = !shouldShowPlayPause
        }
    }
}
