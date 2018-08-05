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
    
    static func instantiateFromStoryboard(uninstaller: Uninstaller) -> MBPodcastsViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MBPodcastsViewController") as! MBPodcastsViewController
        // swiftlint:enable force_cast
        vc.tabBarItem = UITabBarItem(title: "Podcasts", image: UIImage(named: "headphones-gray"), selectedImage: UIImage(named: "headphones-selected"))
        vc.uninstaller = uninstaller
        return vc
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
        
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "filter"), style: .done, target: self, action: #selector(MBPodcastsViewController.filter))
        
        self.loadData()
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
        }.catch { error in
            print("error fetching podcasts: \(error)")
        }
    }
    
    private func showPodcasts() {
        let visibleStreams = self.podcastStore.getVisibleStreams()
        self.visiblePodcasts = self.podcasts.filter({ (podcast) -> Bool in
            visibleStreams.contains(podcast.feed)
        })
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.savedPodcastTitles = Set(self.podcastStore.getSavedPodcastsTitles())
        self.showPodcasts()
    }
    
    @objc func filter() {
        if let delegate = self.delegate {
            delegate.filterPodcasts()
        }
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
        let _ = MBClient().getPodcast(url: url).then { data -> Void in
            self.podcastStore.savePodcastData(data: data, path: title)
            self.savedPodcastTitles.insert(title)
            self.currentlyDownloadingTitles.remove(title)
            self.tableView.reloadData()
        }
    }
    
    func removePodcast(title: String) {
        let _ = uninstaller?.uninstall(id: title).then { uninstalled -> Void in
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
}
