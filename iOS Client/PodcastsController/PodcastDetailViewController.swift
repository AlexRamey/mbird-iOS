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

class PodcastDetailViewController: UIViewController, PodcastPlayerSubscriber {
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
    
    var currentProgress: Double = 0.0
    var totalDuration: Double = 0.0
    var fullImageSize: CGFloat = 0.0
    var isPlaying: Bool = false
    
    var player: PodcastPlayer!
    var selectedPodcast: Podcast!
    var timeFormatter: DateComponentsFormatter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = self.selectedPodcast.title
        let imageName = self.selectedPodcast.image
        imageView.image = UIImage(named: imageName)
        backgroundImageView.image = UIImage(named: imageName)
        self.navigationItem.title = selectedPodcast.feed.title
        
        durationSlider.addTarget(self, action: #selector(onSeek(slider:event:)), for: .valueChanged)
        durationSlider.setValue(0.0, animated: false)
        
        // Sets the nav bar to be transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        fullImageSize = view.bounds.height * 0.25
        self.imageWidthConstraint.constant = fullImageSize
        self.imageHeightConstraint.constant = fullImageSize
        
        self.player.playPodcast(self.selectedPodcast)
        self.currentProgress = self.player.getCurrentProgress()
        self.totalDuration = self.player.getTotalDuration()
        self.updateCurrentDuration()
        self.player.subscribe(self)
        
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
        self.imageView.layer.shadowPath = UIBezierPath(rect: self.imageView.bounds).cgPath
        self.imageView.layer.shadowRadius = 20
        self.imageView.layer.shadowOpacity = 0.4
        self.imageView.layer.shadowOffset = CGSize(width: -5, height: -5)
    }


    @IBAction func pressPlayPause(_ sender: Any) {
        self.player.togglePlayPause()
    }
    
    @objc func onSeek(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            let secondToSeekTo = Double(slider.value) * (self.totalDuration)
            switch touchEvent.phase {
            case .moved:
                self.currentProgress = secondToSeekTo
                self.updateCurrentDuration()
            case .ended:
                self.player.seek(to: secondToSeekTo)
            default:
                break
            }
        }
    }
    
    func animateImage(size: CGSize, duration: CFTimeInterval) {
        var shadowRect = imageView.bounds
        let fromRect = CGRect(x: shadowRect.origin.x, y: shadowRect.origin.y, width: shadowRect.width + 10, height: shadowRect.height + 10)
        shadowRect.size = CGSize(width: size.width + 10, height: size.height + 10)
        let shadowAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.shadowPath))
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
    
    static func instantiateFromStoryboard(podcast: Podcast, player: PodcastPlayer) -> PodcastDetailViewController {
        // swiftlint:disable force_cast
        let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastDetailViewController") as! PodcastDetailViewController
        // swiftlint:enable force_cast
        detailVC.selectedPodcast = podcast
        detailVC.player = player
        
        var timeFormatter = DateComponentsFormatter()
        timeFormatter.unitsStyle = .positional
        timeFormatter.allowedUnits = [ .hour, .minute, .second ]
        timeFormatter.zeroFormattingBehavior = [ .pad ]
        detailVC.timeFormatter = timeFormatter
        
        return detailVC
    }
    
    private func updateCurrentDuration() {
        self.timeFormatter.allowedUnits = self.totalDuration >= Double(3600) ? [.hour, .minute, .second] : [.minute, .second]
        
        self.durationLabel.text = timeFormatter.string(from: self.currentProgress)
        self.totalDurationLabel.text = timeFormatter.string(from: self.totalDuration)
        
        if self.totalDuration > 0.0 {
            self.durationSlider.setValue(Float(self.currentProgress/self.totalDuration), animated: true)
        }
    }
    
    // MARK: - Podcast Player Subscriber
    func notify(currentProgress: Double, totalDuration: Double, isPlaying: Bool) {
        print("isPlaying: \(isPlaying) self.isPlaying \(self.isPlaying)")
        DispatchQueue.main.async {
            self.currentProgress = currentProgress
            self.totalDuration = totalDuration
            self.updateCurrentDuration()
            
            if isPlaying != self.isPlaying {
                if isPlaying {
                    // just turned on
                    self.playPauseButton.setImage(#imageLiteral(resourceName: "pause-bars"), for: .normal)
                    self.animateImage(size: CGSize(width: self.fullImageSize * 0.75, height: self.fullImageSize * 0.75), duration: 0.6)
                } else {
                    // just turned off
                    self.playPauseButton.setImage(#imageLiteral(resourceName: "play-arrow"), for: .normal)
                    self.animateImage(size: CGSize(width: self.fullImageSize, height: self.fullImageSize), duration: 0.6)
                }
            }
            
            self.isPlaying = isPlaying
        }
    }
}
