//
//  MBDevotionsViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

class MBDevotionsViewController: UIViewController, StoreSubscriber, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var store: MBStore!
    var devotions: [LoadedDevotion] = []
    var cellReusableId: String = "DevotionTableViewCell"
    override func viewDidLoad() {
        super.viewDidLoad()
        store = MBStore()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.register(UINib(nibName: cellReusableId, bundle: nil), forCellReuseIdentifier: cellReusableId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MBStore.sharedStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MBStore.sharedStore.unsubscribe(self)
    }
    
    static func instantiateFromStoryboard() -> MBDevotionsViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DevotionsViewController") as! MBDevotionsViewController
        // swiftlint:enable force_cast
    }
    
    func newState(state: MBAppState) {
        switch state.devotionState.devotions {
        case .error:
            break
        case .initial:
            break
        case .loading:
            break
        case .loaded(let loadedDevotions):
            self.devotions = loadedDevotions
            tableView.reloadData()
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let devotion = devotions[indexPath.row]
        //swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReusableId) as! DevotionTableViewCell
        //swiftlint:enable force_cast
        cell.configure(devotion: devotion)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devotions.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       let devotion = devotions[indexPath.row]
        MBStore.sharedStore.dispatch(SelectedDevotion(devotion: devotion))
        do {
            try store.saveDevotions(devotions: devotions)
        } catch {
            //There was an error saving devotion as read so reverse
            print("Error marking devotion as read")
            devotions[indexPath.row].read = false
            MBStore.sharedStore.dispatch(LoadedDevotions(devotions: .loaded(data: devotions)))
        }
    }
}
