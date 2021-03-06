//
//  MBPodcastsViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import PromiseKit

class MBPodcastsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var podcasts: [Podcast] = []
    var visiblePodcasts: [Podcast] = []
    let cellReuseIdentifier = "PodcastTableViewCell"
    
    var podcastDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.dateStyle = .long
        return formatter
    }()
    
    @IBOutlet weak var tableView: UITableView!
    let podcastStore = MBPodcastsStore()
    var savedPodcastTitles: Set<String> = Set<String>()
    var currentlyDownloadingTitles: Set<String> = Set<String>()
    weak var delegate: PodcastTableViewDelegate?
    var uninstaller: Uninstaller?
    
    // refresh control
    private let refreshControl = UIRefreshControl()
    var isFirstAppearance = true
    
    static func instantiateFromStoryboard(uninstaller: Uninstaller) -> MBPodcastsViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MBPodcastsViewController") as! MBPodcastsViewController
        // swiftlint:enable force_cast
        viewController.tabBarItem = UITabBarItem(title: "Podcasts", image: UIImage(named: "headphones-gray"), selectedImage: UIImage(named: "headphones-selected"))
        viewController.uninstaller = uninstaller
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\u{00B7}\u{00B7}\u{00B7}   PODCASTS   \u{00B7}\u{00B7}\u{00B7}"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        self.tabBarItem.title = "Podcasts"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: cellReuseIdentifier, bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 110
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 235.0/255.0, green: 96.0/255.0, blue: 93.0/255.0, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Updating ...", attributes: nil)
        
        self.navigationController?.navigationBar.isTranslucent = true
        let filterBarButton = UIBarButtonItem(image: UIImage(named: "filter"), style: .done, target: self, action: #selector(MBPodcastsViewController.filter))
        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(MBPodcastsViewController.viewInfo), for: .touchUpInside)
        let infoBarButton = UIBarButtonItem(customView: infoButton)
        self.navigationItem.rightBarButtonItem = filterBarButton
        self.navigationItem.leftBarButtonItem = infoBarButton
    }
    
    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        if sender.isRefreshing {
            self.loadData()
        }
    }
    
    private func loadData() {
        firstly { () -> Promise<[Podcast]> in
            self.podcastStore.getSavedPodcasts()
        }.then { podcasts -> Promise<[Podcast]> in
            self.podcasts = podcasts
            self.showPodcasts()
            return self.podcastStore.syncPodcasts()
        }.then { podcasts -> Void in
            self.podcasts = podcasts
            self.showPodcasts()
        }.always {
            self.refreshControl.endRefreshing()
        }.catch { error in
            print("error fetching podcasts: \(error)")
        }
    }
    
    private func showPodcasts() {
        let enabledFilterOptions = self.podcastStore.getEnabledFilterOptions()
        let visibleStreams: [PodcastStream] = enabledFilterOptions.compactMap {
            if case PodcastFilterOption.stream(let stream) = $0 {
                return stream
            } else {
                return nil
            }
        }
        let showDownloadedPodcasts = enabledFilterOptions.contains(where: {
            if case PodcastFilterOption.downloaded = $0 {
                return true
            } else {
                return false
            }
        })
        self.visiblePodcasts = self.podcasts.filter({ (podcast) -> Bool in
            if showDownloadedPodcasts {
                return savedPodcastTitles.contains(podcast.title ?? "")
            } else {
                return visibleStreams.contains(podcast.feed)
            }
        })
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.savedPodcastTitles = Set(self.podcastStore.getSavedPodcastsTitles())
        
        if self.isFirstAppearance {
            self.isFirstAppearance = false
            
            // the following line ensures that the refresh control has the correct tint/text on first use
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
            self.refreshControl.beginRefreshing()
            self.loadData()
        } else {
            self.showPodcasts()
        }
    }
    
    @objc func filter() {
        if let delegate = self.delegate {
            delegate.filterPodcasts()
        }
    }
    
    @objc func viewInfo(_ sender: Any) {
        delegate?.viewInfo()
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.visiblePodcasts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier) as! PodcastTableViewCell
        // swiftlint:enable force_cast
        
        let podcast = visiblePodcasts[indexPath.row]
        let saved = self.savedPodcastTitles.contains(podcast.title ?? "")
        let downloading = self.currentlyDownloadingTitles.contains(podcast.title ?? "")
        cell.configure(title: podcast.title ?? "",
                       image: UIImage(named: podcast.image),
                       date: podcastDateFormatter.string(from: podcast.pubDate),
                       guid: podcast.guid ?? "",
                       saved: saved,
                       downloading: downloading)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = self.delegate {
            delegate.didSelectPodcast(self.visiblePodcasts[indexPath.row])
        }
    }
}

extension MBPodcastsViewController: PodcastDownloadingDelegate {
    func downloadPodcast(url: String, title: String) {
        print("download podcast at url: \(url)")
        guard let url = URL(string: url) else { return }
        self.currentlyDownloadingTitles.insert(title)
        _ = MBClient().getPodcast(url: url).then { data -> Void in
            self.podcastStore.savePodcastData(data: data, path: title)
            self.savedPodcastTitles.insert(title)
            self.currentlyDownloadingTitles.remove(title)
            self.tableView.reloadData()
        }
    }
    
    func removePodcast(title: String) {
        _ = uninstaller?.uninstall(podcastId: title).then { uninstalled -> Void in
            if uninstalled {
                self.savedPodcastTitles.remove(title)
                self.tableView.reloadData()
            }
        }
    }
}


protocol PodcastTableViewDelegate: class {
    func didSelectPodcast(_ podcast: Podcast)
    func filterPodcasts()
    func viewInfo()
}
