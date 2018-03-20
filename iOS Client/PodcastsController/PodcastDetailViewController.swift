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
    
    var totalDuration: Double?
    
    @IBOutlet weak var durationSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var totalDurationLabel: UILabel!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var timeFormatter: DateComponentsFormatter?
    
    var delegate: PodcastDetailViewControllerDelegate?
    var playerState: PlayerState?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
        configureFormatter()
        durationSlider.addTarget(self, action: #selector(onSeek(slider:event:)), for: .valueChanged)
        durationSlider.setValue(0.0, animated: false)
        playerState = .initialized
        self.imageView.layer.shadowPath = UIBezierPath(rect:self.imageView.bounds).cgPath
        self.imageView.layer.shadowRadius = 20
        self.imageView.layer.shadowOpacity = 0.4
        self.imageView.layer.shadowOffset = CGSize(width: -5, height: -5)
        // Sets the nav bar to be transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
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
    
    func configureFormatter() {
        timeFormatter = DateComponentsFormatter()
        timeFormatter?.unitsStyle = .positional
        timeFormatter?.allowedUnits = [ .hour, .minute, .second ]
        timeFormatter?.zeroFormattingBehavior = [ .pad ]
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
            case .ended:
                delegate?.seek(to: secondToSeekTo)
            default:
                break
            }
        }
    }
    
    func animateImage(size: CGSize, duration: CFTimeInterval) {
        var shadowRect = imageView.bounds
        var fromRect = CGRect(x: shadowRect.origin.x, y: shadowRect.origin.y, width: shadowRect.width + 10, height: shadowRect.height + 10)
        shadowRect.size = CGSize(width: size.width + 10, height: size.height + 10)
        let shadowAnimation = CABasicAnimation(keyPath:  #keyPath(CALayer.shadowPath))
        shadowAnimation.fromValue = UIBezierPath(rect: fromRect).cgPath
        shadowAnimation.toValue = UIBezierPath(rect: shadowRect).cgPath
        shadowAnimation.isRemovedOnCompletion = false
        shadowAnimation.fillMode = kCAFillModeForwards
        shadowAnimation.duration = duration
        shadowAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.imageWidthConstraint.constant = size.width
        self.imageHeightConstraint.constant = size.height
        self.imageView.layer.add(shadowAnimation, forKey: #keyPath(CALayer.shadowPath))
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    static func instantiateFromStoryboard() -> PodcastDetailViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastDetailViewController") as! PodcastDetailViewController
        // swiftlint:enable force_cast
    }
    
    func newState(state: MBAppState) {
        switch state.podcastsState.player {
        case .initialized, .error, .paused, .finished:
            playPauseButton.setImage(#imageLiteral(resourceName: "play-arrow"), for: .normal)
            if playerState == .playing, playerState != .initialized { animateImage(size: CGSize(width: 150, height: 150), duration: 0.6)}
        case .playing:
            playPauseButton.setImage(#imageLiteral(resourceName: "pause-bars"), for: .normal)
            if playerState != .playing, playerState != .initialized { animateImage(size: CGSize(width: 200, height: 200), duration: 0.6)}
        }
        playerState = state.podcastsState.player
        titleLabel.text = state.podcastsState.selectedPodcast?.title
        if let imageName = state.podcastsState.selectedPodcast?.image {
           imageView.image = UIImage(named: imageName)
            backgroundImageView.image = UIImage(named: imageName)
        }
        self.navigationItem.title = state.podcastsState.selectedPodcast?.feedName
    }
    
    func updateCurrentDuration(current: Double, total: Double ) {
        totalDuration = total
        timeFormatter?.allowedUnits = total >= Double(3600) ? [.hour, .minute, .second] : [.minute, .second]
        durationLabel.text = timeFormatter?.string(from: current)
        totalDurationLabel.text = timeFormatter?.string(from: total)
        guard let validTime = totalDuration, validTime > 0 else {
            return
        }
        durationSlider.setValue(Float(current/validTime), animated: true)
    }
}
