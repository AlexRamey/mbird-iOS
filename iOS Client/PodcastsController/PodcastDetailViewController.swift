//
//  PodcastDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/21/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class PodcastDetailViewController: UIViewController, StoreSubscriber {
    
    var podcast: MBPodcast?

    @IBOutlet weak var titleLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    static func instantiateFromStoryboard() -> PodcastDetailViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastDetailViewController") as! PodcastDetailViewController
        // swiftlint:enable force_cast
    }
    
    func newState(state: MBAppState) {
        podcast = state.podcastsState.selectedPodcast
        titleLabel.text = podcast?.title
    }

}
