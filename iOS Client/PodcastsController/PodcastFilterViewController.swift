//
//  PodcastFilterViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 4/9/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class PodcastsFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, StoreSubscriber {
    
    @IBOutlet weak var tableView: UITableView!
    var visibleStreams: Set<PodcastStream> = Set<PodcastStream>()
    var streams: [PodcastStream] = []
    let filterReuseIdentifier: String = "PodcastFilterTableViewCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "PodcastFilterTableViewCell", bundle: nil), forCellReuseIdentifier: filterReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        tableView.tableFooterView = nil
        navigationItem.title = "Filter"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }
    
    static func instantiateFromStoryboard() -> PodcastsFilterViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastFilterViewController") as! PodcastsFilterViewController
        // swiftlint:enable force_cast
    }
    
    func newState(state: MBAppState) {
        streams = state.podcastsState.streams
        visibleStreams = state.podcastsState.visibleStreams
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: filterReuseIdentifier) as? PodcastFilterTableViewCell,
            indexPath.row < streams.count else {
                return UITableViewCell()
        }
        let stream = streams[indexPath.row]
        cell.configure(image: UIImage(named: stream.imageName), stream: stream, on: visibleStreams.contains(stream))
        return cell
    }
}
