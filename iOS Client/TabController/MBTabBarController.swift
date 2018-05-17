//
//  MBTabBarController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift
import UIKit

class MBTabBarController: UITabBarController, StoreSubscriber {
    
    var playPauseView: PlayPauseView!
    var playerState: PlayerState = .initialized
    
    static func instantiateFromStoryboard() -> MBTabBarController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseTabController") as! MBTabBarController
        // swiftlint:enable force_cast
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
        MBStore.sharedStore.dispatch(PlayPausePodcast())
    }
    
    @objc func cancelPodcast(_ sender: UIButton) {
        MBStore.sharedStore.dispatch(FinishedPodcast())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         configurePlayPauseView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func select(tab: Tab) {
        self.selectedIndex = tab.rawValue
    }
    
    func newState(state: MBAppState) {
        if let podImageName = state.podcastsState.selectedPodcast?.image {
            playPauseView.image.image = UIImage(named: podImageName)
        }
        var shouldShowPlayPause = false
        switch state.podcastsState.player {
        case .initialized:
            break
        case .paused, .error:
            playPauseView.toggleButton.setImage(UIImage(named: "play-arrow"), for: .normal)
            shouldShowPlayPause = true
        case .playing:
            playPauseView.toggleButton.setImage(UIImage(named: "pause-bars"), for: .normal)
            playPauseView.titleLabel.text = state.podcastsState.selectedPodcast?.title
            shouldShowPlayPause = true
        case .finished:
            shouldShowPlayPause = false
        }
        playerState = state.podcastsState.player
        if state.navigationState.selectedTab == .podcasts,
            let routes = state.navigationState.routes[.podcasts],
            let topRoute = routes.last,
            case .detail = topRoute {
            playPauseView?.isHidden = true
        } else if shouldShowPlayPause {
            playPauseView?.isHidden = false
        } else {
            playPauseView?.isHidden = true
        }
    }

}
