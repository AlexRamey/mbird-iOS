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
    var filterOptions: [PodcastFilterOption] = []
    var enabledOptions: [PodcastFilterOption] = []
    var repository: PodcastsRepository!
    var handler: PodcastFilterHandler?
    
    let filterReuseIdentifier: String = "PodcastFilterTableViewCell"
    
    var shouldHideStreamOptions: Bool {
        return enabledOptions.contains(where: {
            switch $0 {
            case .downloaded: return true
            case .stream: return false
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "FILTER"
        tableView.register(UINib(nibName: "PodcastFilterTableViewCell", bundle: nil), forCellReuseIdentifier: filterReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        tableView.tableFooterView = nil
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(PodcastsFilterViewController.viewInfo), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        self.loadData()
    }
    
    func loadData() {
        self.filterOptions = self.repository.getStreams().map { PodcastFilterOption.stream($0) }
        self.filterOptions.append(.downloaded)
        self.enabledOptions = self.repository.getEnabledFilterOptions()
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
        if shouldHideStreamOptions {
            return 1
        } else {
            return self.filterOptions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: filterReuseIdentifier) as? PodcastFilterTableViewCell else {
                return UITableViewCell()
        }
        cell.delegate = self
        let option: PodcastFilterOption
        if shouldHideStreamOptions {
            option = .downloaded
        } else {
            option = filterOptions[indexPath.row]
        }
        switch option {
        case .stream(let stream):
            cell.configure(image: UIImage(named: stream.imageName),
                           title: stream.title,
                           option: option,
                           isOn: optionsContainsStream(enabledOptions, stream: stream))
        case .downloaded:
            cell.configure(image: UIImage(named: "download-done"),
                           title: "Downloaded Podcasts",
                           option: option,
                           isOn: shouldHideStreamOptions)
        }
        return cell
    }
    
    // MARK: - PodcastFilterDelegate
    func toggleFilterOption(_ option: PodcastFilterOption, isOn: Bool) {
        self.repository.setFilter(option: option, isVisible: isOn)
        loadData()
    }
    
    private func optionsContainsStream(_ options: [PodcastFilterOption], stream: PodcastStream) -> Bool {
        return options.contains(where: {
            if case .stream(let optionStream) = $0 {
                return optionStream == stream
            } else {
                return false
            }
        })
    }
}

enum PodcastFilterOption {
    case stream(PodcastStream)
    case downloaded
    
    var key: String {
        switch self {
        case .stream(let stream):
            return stream.rawValue
        case .downloaded:
            return "downloaded"
        }
    }
}
