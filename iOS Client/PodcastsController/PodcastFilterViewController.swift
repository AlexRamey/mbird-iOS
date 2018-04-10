//
//  PodcastFilterViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 4/9/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import ReSwift
import UIKit

class PodcastsFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, StoreSubscriber {
    
    @IBOutlet weak var tableView: UITableView!
    var visibleStreams: Set<PodcastStream> = Set<PodcastStream>()
    var streams: [PodcastStream] = [.pz, .mockingCast, .mockingPulpit]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: PodcastFilterTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: PodcastFilterTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        tableView.tableFooterView = nil
        navigationItem.title = "Filter"
        configureBackButton()
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
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToPodcasts(sender:)))
    }
    
    @objc func backToPodcasts(sender: AnyObject) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    
    func newState(state: MBAppState) {
        visibleStreams = state.podcastsState.visiblePodcasts
        
        tableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PodcastFilterTableViewCell.reuseIdentifier) as? PodcastFilterTableViewCell,
            indexPath.row < streams.count else {
                return UITableViewCell()
        }
        let stream = streams[indexPath.row]
        cell.configure(image: UIImage(named: stream.imageName), podcast: stream, on: visibleStreams.contains(stream))
        return cell
    }
}
