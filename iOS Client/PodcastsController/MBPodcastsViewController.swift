//
//  MBPodcastsViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class MBPodcastsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, StoreSubscriber {

    var podcasts: [MBPodcast] = []
    let cellReuseIdentifier = "PodcastTableViewCell"
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: cellReuseIdentifier, bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }
    
    // MARK - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PodcastTableViewCell
        // swiftlint:enable force_cast
        if indexPath.row < podcasts.count {
            let podcast = podcasts[indexPath.row]
            cell.configure(title: podcast.title ?? "")
        } else {
            cell.configure(title: "")
        }
        return cell
    }
    
    // MARK - StoreSubscriber
    func newState(state: MBAppState) {
        let podcastsState = state.podcastsState
        switch podcastsState.podcasts {
        case .initial, .error, .loading:
            break
        case .loaded(let data):
            self.podcasts = data
            self.tableView.reloadData()
        }
    }
    
    static func instantiateFromStoryboard() -> MBPodcastsViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MBPodcastsViewController") as! MBPodcastsViewController
        // swiftlint:enable force_cast
    }

}