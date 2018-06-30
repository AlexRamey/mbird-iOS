//
//  SearchResultsTableViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UITableViewController, UISearchResultsUpdating {
    var searchBarHolder: SearchBarHolder?
    let reuseIdentifier = "searchResultCellReuseIdentifier"
    
    enum SearchOperation {
        case inProgress
        case finished(results: [Article])
    }
    
    var results: [Article] = []
    var resultsCache: [String: SearchOperation] = [:]
    
    var firstResponderFlag: Bool = true
    
    // dependencies
    let client = MBClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        
        self.tableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !self.firstResponderFlag {
            self.searchBarHolder?.removeSearchBar()
        }
    }
    
    // MARK: - UI Search Results Updating
    
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.searchBar.isFirstResponder else {
            print("NOT FIRST RESPONDER")
            self.firstResponderFlag = false
            return
        }
        
        self.firstResponderFlag = true
        guard let query = searchController.searchBar.text, query != "" else {
            self.results = []
            self.tableView.reloadData()
            return
        }
        
        // serve from cache if possible
        if let operation = self.resultsCache[query] {
            switch operation {
            case .inProgress:
                // don't issue a request if one is currently outstanding
                return
            case .finished(let articles):
                self.results = articles
                self.tableView.reloadData()
                return
            }
        }
        
        // issue a query to the search API
        self.client.searchArticlesWithCompletion(query: query) { (articles, err) in
            if let err = err {
                print("SEARCH ERROR: \(err.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.resultsCache[query] = .finished(results: articles)
                if searchController.searchBar.text == query {
                    // these results are relevant now!
                    self.results = articles
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = self.results[indexPath.row].title

        return cell
    }
}
