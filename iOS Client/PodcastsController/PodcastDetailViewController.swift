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

class PodcastDetailViewController: UIViewController, StoreSubscriber, PodcastPlayerDelegate {
    var podcast: MBPodcast?
    var totalDuration: Double?
    
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
        durationSlider.addTarget(self, action: #selector(onSeek(slider:event:)), for: .valueChanged)
        durationSlider.setValue(0.0, animated: false)
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
        MBStore.sharedStore.dispatch(PlayPausePodcast())
    }
    
    @objc func onSeek(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            let secondToSeekTo = Double(slider.value) * (totalDuration ?? 0.0)
            switch touchEvent.phase {
            case .moved:
                updateCurrentDuration(current: secondToSeekTo, total: totalDuration ?? 0.0)
                if playerState != .paused {
                    MBStore.sharedStore.dispatch(PlayPausePodcast())
                }
            case .ended:
                MBStore.sharedStore.dispatch(SeekPodcast(toSecond: secondToSeekTo))
            default:
                break
            }
        }
    }
    
    static func instantiateFromStoryboard() -> PodcastDetailViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastDetailViewController") as! PodcastDetailViewController
        // swiftlint:enable force_cast
    }
    
    func newState(state: MBAppState) {
        switch state.podcastsState.player {
        case .error, .initialized, .paused, .finished:
            playPauseButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        case .playing:
            playPauseButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
        podcast = state.podcastsState.selectedPodcast
        titleLabel.text = podcast?.title
        
        playerState = state.podcastsState.player
    }
    
    func updateCurrentDuration(current: Double, total: Double ) {
        totalDuration = total
        durationLabel.text = "\(formatter.string(from: NSNumber(value: current)) ?? "0") / \(formatter.string(from: NSNumber(value: total)) ?? "0")"
        durationSlider.setValue(Float(current/(totalDuration ?? 0.0)), animated: true)
    }
}

protocol PodcastPlayerDelegate: class {
    func updateCurrentDuration(current: Double, total: Double )
    
}
