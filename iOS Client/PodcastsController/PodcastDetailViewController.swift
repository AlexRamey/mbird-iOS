//
//  PodcastDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/21/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import AVKit

protocol PodcastDetailHandler: class {
    func dismissDetail()
}

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
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var fastforwardButton: UIButton!
    
    var currentProgress: Double = 0.0
    var totalDuration: Double = 0.0
    var fullImageSize: CGFloat = 0.0
    var isPlaying: Bool = false
    
    var player: PodcastPlayer!
    var selectedPodcast: Podcast!
    var saved: Bool = false
    var timeFormatter: DateComponentsFormatter!
    
    var podcastStore = MBPodcastsStore()
    var uninstaller: Uninstaller?
    weak var handler: PodcastDetailHandler?
    
    static func instantiateFromStoryboard(podcast: Podcast, player: PodcastPlayer, uninstaller: Uninstaller, handler: PodcastDetailHandler) -> PodcastDetailViewController {
        // swiftlint:disable force_cast
        let detailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastDetailViewController") as! PodcastDetailViewController
        // swiftlint:enable force_cast
        
        detailVC.selectedPodcast = podcast
        detailVC.player = player
        detailVC.handler = handler
        
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.unitsStyle = .positional
        timeFormatter.allowedUnits = [ .hour, .minute, .second ]
        timeFormatter.zeroFormattingBehavior = [ .pad ]
        detailVC.timeFormatter = timeFormatter
        detailVC.uninstaller = uninstaller
        return detailVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = self.selectedPodcast.title
        let imageName = self.selectedPodcast.image
        imageView.image = UIImage(named: imageName)
        backgroundImageView.image = UIImage(named: imageName)
        self.navigationItem.title = selectedPodcast.feed.shortTitle
        self.titleLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 20)
        durationSlider.addTarget(self, action: #selector(onSeek(slider:event:)), for: .valueChanged)
        durationSlider.setValue(0.0, animated: false)
        
        // Sets the nav bar to be transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
        fullImageSize = view.bounds.height * 0.25
        self.imageWidthConstraint.constant = fullImageSize
        self.imageHeightConstraint.constant = fullImageSize
        
        self.player.playPodcast(self.selectedPodcast)
        self.currentProgress = self.player.getCurrentProgress()
        self.totalDuration = self.player.getTotalDuration()
        self.updateCurrentDuration()
        self.player.subscribe(self)
        self.saved = podcastStore.containsSavedPodcast(self.selectedPodcast)
        configureBarButtonItems(downloaded: self.saved)
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
 
        self.imageView.layer.shadowPath = UIBezierPath(rect: self.imageView.bounds).cgPath
        self.imageView.layer.shadowRadius = 20
        self.imageView.layer.shadowOpacity = 0.4
        self.imageView.layer.shadowOffset = CGSize(width: -5, height: -5)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.player.unsubscribe(self)
    }

    @IBAction func pressPlayPause(_ sender: Any) {
        self.player.togglePlayPause()
    }
    
    @IBAction func pressFastForward(_ sender: Any) {
        player?.seek(relative: 15)
    }
    
    @IBAction func pressRewind(_ sender: Any) {
        player?.seek(relative: -15)
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
    
    @IBAction func pressDownloadButton(_ sender: Any) {
        if saved {
            removePodcast()
        } else {
            downloadPodcast()
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
    
    private func updateCurrentDuration() {
        self.timeFormatter.allowedUnits = self.totalDuration >= Double(3600) ? [.hour, .minute, .second] : [.minute, .second]
        
        self.durationLabel.text = timeFormatter.string(from: self.currentProgress)
        self.totalDurationLabel.text = timeFormatter.string(from: self.totalDuration)
        
        if self.totalDuration > 0.0 {
            self.durationSlider.setValue(Float(self.currentProgress/self.totalDuration), animated: true)
        }
    }
    
    private func configureBarButtonItems(downloaded: Bool) {
        self.navigationItem.rightBarButtonItems = [getDownloadBarButton(downloaded: downloaded), getShareBarButton()]
    }
    
    private func getDownloadBarButton(downloaded: Bool) -> UIBarButtonItem {
        return UIBarButtonItem(image: downloaded ? UIImage(named: "download-done") :  UIImage(named: "add"),
                               style: .done,
                               target: self,
                               action: downloaded ?
                                #selector(PodcastDetailViewController.removePodcast) :
                                #selector(PodcastDetailViewController.downloadPodcast))
    }
    
    private func getShareBarButton() -> UIBarButtonItem {
        // return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(PodcastDetailViewController.sharePodcast))
        return UIBarButtonItem(image: UIImage(named: "share-button"), style: .plain, target: self, action: #selector(PodcastDetailViewController.sharePodcast))
    }
    
    @objc private func removePodcast() {
        guard let title = self.selectedPodcast.title else { return }
        _ = uninstaller?.uninstall(podcastId: title).then { uninstalled in
            self.saved = !uninstalled
        }
    }
    
    @objc private func downloadPodcast() {
        guard let path = self.selectedPodcast.guid,
            let title = self.selectedPodcast.title,
            let url = URL(string: path) else {
                return
        }
        _ = MBClient().getPodcast(url: url).then { podcast in
            return self.podcastStore.savePodcastData(data: podcast,
                                                     path: title)
        }.then { _ -> Void in
            self.saved = true
            self.configureBarButtonItems(downloaded: true)
        }
    }
    
    // MARK: - Podcast Player Subscriber
    func notify(currentProgress: Double, totalDuration: Double, isPlaying: Bool, isCanceled: Bool) {
        DispatchQueue.main.async {
            guard !isCanceled else {
                self.handler?.dismissDetail()
                return
            }
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
    
    @objc func sharePodcast(sender: Any) {
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: [ "\(selectedPodcast.feed.title): ", selectedPodcast.title ?? "", selectedPodcast.guid ?? "" ], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [
            .airDrop,
            .assignToContact,
            .openInIBooks,
            .postToFlickr,
            .postToVimeo,
            .print,
            .saveToCameraRoll
        ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
