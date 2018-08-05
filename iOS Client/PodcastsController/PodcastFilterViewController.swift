//
//  PodcastFilterViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 4/9/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

protocol PodcastFilterHandler {
    func viewInfo()
}

class PodcastsFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PodcastFilterDelegate {
    @IBOutlet weak var tableView: UITableView!
    var streams: [PodcastStream] = []
    var repository: PodcastsRepository!
    var handler: PodcastFilterHandler?
    
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "info"), style: .done, target: self, action: #selector(PodcastsFilterViewController.viewInfo))
        
        self.loadData()
    }
    
    func loadData() {
        self.streams = self.repository.getStreams()
        self.tableView.reloadData()
    }
    
    static func instantiateFromStoryboard(repository: PodcastsRepository, handler: PodcastFilterHandler) -> PodcastsFilterViewController {
        // swiftlint:disable force_cast
        let filterVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastFilterViewController") as! PodcastsFilterViewController
        // swiftlint:enable force_cast
        filterVC.repository = repository
        filterVC.handler = handler
        return filterVC
    }
    
    @objc func viewInfo(_ sender: Any) {
        handler?.viewInfo()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.streams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: filterReuseIdentifier) as? PodcastFilterTableViewCell else {
                return UITableViewCell()
        }
        cell.delegate = self
        let stream = streams[indexPath.row]
        cell.configure(image: UIImage(named: stream.imageName), stream: stream, on: self.repository.getVisibleStreams().contains(stream))
        return cell
    }
    
    // MARK: - PodcastFilterDelegate
    func filterStream(_ stream: PodcastStream, on: Bool) {
        self.repository.setStreamVisible(stream: stream, isVisible: on)
    }
}
