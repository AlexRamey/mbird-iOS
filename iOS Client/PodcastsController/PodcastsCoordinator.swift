//
//  PodcastsCoordinator.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class PodcastsCoordinator: NSObject, Coordinator, PodcastTableViewDelegate {
    var articleDAO: ArticleDAO?
    var childCoordinators: [Coordinator] = []
    var podcastDetailViewController: PodcastDetailViewController? {
        return navigationController.viewControllers.last as? PodcastDetailViewController
    }
    
    var rootViewController: UIViewController {
        return navigationController
    }
    
    let podcastsStore: MBPodcastsStore
    let player: PodcastPlayer
    
    private lazy var navigationController: UINavigationController = {
        return UINavigationController()
    }()
    
    init(store: MBPodcastsStore, player: PodcastPlayer) {
        self.podcastsStore = store
        self.player = player
    }
    
    func start() {
        let podcastsController = MBPodcastsViewController.instantiateFromStoryboard()
        podcastsController.delegate = self
        navigationController.pushViewController(podcastsController, animated: true)
    }
    
    // MARK: - PodcastTableViewDelegate
    func didSelectPodcast(_ podcast: Podcast) {
        let detailViewController = PodcastDetailViewController.instantiateFromStoryboard(podcast: podcast, player: player)
        self.navigationController.pushViewController(detailViewController, animated: true)
    }
    
    func filterPodcasts() {
        let filterViewController = PodcastsFilterViewController.instantiateFromStoryboard(repository: self.podcastsStore)
        self.navigationController.pushViewController(filterViewController, animated: true)
    }
}
