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
    var playPauseStackView: UIStackView!
    var podcastTitleLabel: UILabel!
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
        playPauseView.backgroundColor = UIColor.white
        playPauseView.layer.shadowOffset = CGSize(width: 0, height: -10)
        playPauseView.layer.shadowRadius = 7
        view.addSubview(playPauseView)
        playPauseView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        playPauseView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        playPauseView.bottomAnchor.constraint(equalTo: tabBar.topAnchor).isActive = true
        playPauseView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playPauseView.isHidden = true
        
        playPauseStackView = UIStackView()
        playPauseStackView.translatesAutoresizingMaskIntoConstraints = false
        playPauseView.addSubview(playPauseStackView)
        playPauseStackView.leadingAnchor.constraint(equalTo: playPauseView.leadingAnchor).isActive = true
        playPauseStackView.trailingAnchor.constraint(equalTo: playPauseView.trailingAnchor).isActive = true
        playPauseStackView.topAnchor.constraint(equalTo: playPauseView.topAnchor).isActive = true
        playPauseStackView.bottomAnchor.constraint(equalTo: playPauseView.bottomAnchor).isActive = true
        
        playPauseButton = UIButton()
        playPauseButton.setImage(UIImage(named: "play-arrow"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(togglePlayPause(_:)), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(playPauseButton)
        container.topAnchor.constraint(equalTo: playPauseButton.topAnchor, constant: 10).isActive = true
        container.bottomAnchor.constraint(equalTo: playPauseButton.bottomAnchor, constant: 10).isActive = true
        container.leadingAnchor.constraint(greaterThanOrEqualTo: playPauseButton.leadingAnchor, constant: 15).isActive = true
        container.trailingAnchor.constraint(greaterThanOrEqualTo: playPauseButton.trailingAnchor, constant: -15).isActive = true
        playPauseButton.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        playPauseButton.widthAnchor.constraint(equalTo: playPauseButton.heightAnchor).isActive = true
        container.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        playPauseStackView.addArrangedSubview(container)
        
        podcastTitleLabel = UILabel()
        podcastTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        podcastTitleLabel.numberOfLines = 0
        podcastTitleLabel.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal)
        playPauseStackView.addArrangedSubview(podcastTitleLabel)
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
        
        switch state.podcastsState.player {
        case .initialized:
            break
        case .paused, .error:
            playPauseButton.setImage(UIImage(named: "play-arrow"), for: .normal)
            playPauseView?.isHidden = false
        case .playing:
            playPauseButton.setImage(UIImage(named: "pause-bars"), for: .normal)
            podcastTitleLabel.text = state.podcastsState.selectedPodcast?.title
            playPauseView?.isHidden = false
        case .finished:
            playPauseView?.isHidden = true
        }
        playerState = state.podcastsState.player
    }

}
