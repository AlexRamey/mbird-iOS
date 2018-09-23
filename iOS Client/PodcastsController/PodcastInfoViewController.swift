//
//  PodcastInfoViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/4/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

protocol PodcastInfoHandler {
    func dismissInfo()
}

class PodcastInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var repository: PodcastsRepository!
    var streams: [PodcastStream] = []
    let podcastInfoReusableId = "PodcastInfoTableViewCell"
    var handler: PodcastInfoHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: podcastInfoReusableId, bundle: nil), forCellReuseIdentifier: podcastInfoReusableId)
        tableView.rowHeight = UITableViewAutomaticDimension
        self.title = "\u{00B7}\u{00B7}\u{00B7}   PODCASTS   \u{00B7}\u{00B7}\u{00B7}"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(PodcastInfoViewController.dismissInfo))
        self.tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        streams = repository.getStreams()
        tableView.reloadData()
    }

    static func instantiateFromStoryboard(repository: PodcastsRepository, handler: PodcastInfoHandler) -> PodcastInfoViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PodcastInfoViewController") as! PodcastInfoViewController
        // swiftlint:enable force_cast
        viewController.repository = repository
        viewController.handler = handler
        return viewController
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stream = streams[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: podcastInfoReusableId) as? PodcastInfoTableViewCell,
            let image = UIImage(named: stream.imageName) {
            cell.configure(image: image, name: stream.title, description: stream.description)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    @objc func dismissInfo(_ sender: Any) {
        handler?.dismissInfo()
    }
    
}
