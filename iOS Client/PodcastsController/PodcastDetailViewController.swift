//
//  PodcastDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/21/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift
import AVKit

class PodcastDetailViewController: UIViewController, StoreSubscriber {
    
    var podcast: MBPodcast?
    
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    
    let formatter: NumberFormatter = {
        let f = NumberFormatter()
        return f
    }()
    
    var playerState: PlayerState = .initialized
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToPodcasts(sender:)))
    }
    
    @objc func backToPodcasts(sender: AnyObject) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }

    @IBAction func pressPlayPause(_ sender: Any) {
        switch playerState {
        case .playing:
            MBStore.sharedStore.dispatch(PausePodcast())
        case .paused, .initialized, .error:
            MBStore.sharedStore.dispatch(ResumePodcast())
        case .finished:
            break
        }
    }
    
    static func instantiateFromStoryboard() -> PodcastDetailViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastDetailViewController") as! PodcastDetailViewController
        // swiftlint:enable force_cast
    }
    
    func newState(state: MBAppState) {
        podcast = state.podcastsState.selectedPodcast
        titleLabel.text = podcast?.title
        switch state.podcastsState.player {
        case .error, .initialized, .paused, .finished:
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        case .playing:
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
        playerState = state.podcastsState.player
        durationLabel.text = formatter.string(from: NSNumber(value: state.podcastsState.currentDuration))
    }
}
