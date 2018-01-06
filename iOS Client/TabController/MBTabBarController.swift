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
    
    var playPauseView: UIView!
    var playPauseButton: UIButton!
    var playerState: PlayerState = .initialized
    
    static func instantiateFromStoryboard() -> MBTabBarController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BaseTabController") as! MBTabBarController
        // swiftlint:enable force_cast
    }
    func configurePlayPauseView() {
        let tabBar = self.tabBar
        playPauseView = UIView()
        playPauseView.translatesAutoresizingMaskIntoConstraints = false
        playPauseView.backgroundColor = UIColor.gray
        view.addSubview(playPauseView)
        playPauseView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playPauseView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playPauseView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playPauseView.bottomAnchor.constraint(equalTo: tabBar.topAnchor).isActive = true
        playPauseView.isHidden = true
        
        playPauseButton = UIButton()
        playPauseButton.setTitle("Play", for: .normal)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause(_:)), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseView.addSubview(playPauseButton)
        playPauseButton.centerXAnchor.constraint(equalTo: playPauseView.centerXAnchor).isActive = true
        playPauseButton.centerYAnchor.constraint(equalTo: playPauseView.centerYAnchor).isActive = true
    }
    
    @objc func togglePlayPause(_ sender: UIButton) {
        MBStore.sharedStore.dispatch(PlayPausePodcast())
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
        if state.podcastsState.player != .initialized {
            playPauseView?.isHidden = false
        }
        
        switch state.podcastsState.player {
        case .initialized, .paused, .error:
            playPauseButton.setTitle("Play", for: .normal)
        case .playing:
            playPauseButton.setTitle("Pause", for: .normal)
        }
        playerState = state.podcastsState.player
    }

}
