//
//  PodcastsCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class PodcastsCoordinator: NSObject, Coordinator, PodcastTableViewDelegate, UninstallerDelegate, PodcastDetailHandler {
    var childCoordinators: [Coordinator] = []
    var podcastDetailViewController: PodcastDetailViewController? {
        return navigationController.viewControllers.last as? PodcastDetailViewController
    }
    
    var rootViewController: UIViewController {
        return navigationController
    }
    
    let podcastsStore: MBPodcastsStore
    let player: PodcastPlayer
    var uninstaller: Uninstaller
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(store: MBPodcastsStore, player: PodcastPlayer) {
        self.podcastsStore = store
        self.player = player
        self.uninstaller = PodcastUninstaller(store: self.podcastsStore, player: self.player)
    }
    
    func start() {
        let podcastsController = MBPodcastsViewController.instantiateFromStoryboard(uninstaller: uninstaller)
        podcastsController.delegate = self
        uninstaller.delegate = self
        navigationController.pushViewController(podcastsController, animated: true)
    }
    
    // MARK: - PodcastTableViewDelegate
    func didSelectPodcast(_ podcast: Podcast) {
        let detailViewController = PodcastDetailViewController.instantiateFromStoryboard(podcast: podcast, player: player, uninstaller: uninstaller, handler: self)
        self.navigationController.pushViewController(detailViewController, animated: true)
    }
    
    func filterPodcasts() {
        let filterViewController = PodcastsFilterViewController.instantiateFromStoryboard(repository: self.podcastsStore)
        self.navigationController.pushViewController(filterViewController, animated: true)
    }
    
    // MARK: - UninstallerDelegate
    func alertForUninstallItem(completion: @escaping ((UninstallApprovalStatus) -> Void)) {
        let alert = UIAlertController(title: "Are you sure you would like to uninstall this podcast?", message: "Doing so will force the playback to end.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in completion(.deny) })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ -> Void in completion(.approve) } )
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - PodcastDetailHandler
    func dismissDetail() {
        navigationController.popViewController(animated: false)
    }
}
