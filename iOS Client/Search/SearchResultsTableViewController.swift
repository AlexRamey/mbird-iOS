//
//  SearchResultsTableViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    let reuseIdentifier = "searchResultCellReuseIdentifier"
    var searchBar: UISearchBar?
    var store: MBArticlesStore!
    
    enum SearchOperation {
        case inProgress
        case finished(results: [Article])
    }
    
    var results: [Article] = []
    var resultsCache: [String: SearchOperation] = [:]
    
    // dependencies
    let client = MBClient()
    
    static func instantiateFromStoryboard() -> SearchResultsTableViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticleSearchResultsVC") as! SearchResultsTableViewController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        if let searchBar = self.searchBar {
            self.automaticallyAdjustsScrollViewInsets = false
            self.tableView.contentInset = UIEdgeInsets(top: searchBar.frame.size.height, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: - UI Search Results Updating
    
    func updateSearchResults(for searchController: UISearchController) {
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
            
            var results = articles
            for index in 0..<results.count {
                results[index].resolveAuthor(dao: self.store)
                results[index].resolveCategories(dao: self.store)
            }
            
            self.client.getImagesById(results.map {$0.imageId}, completion: { (images) in
                // note n^2 performance improvement opportunity if we need it
                for index in 0..<results.count {
                    results[index].image = images.first(where: { (image) -> Bool in
                        results[index].imageId == image.id
                    })
                }
                
                DispatchQueue.main.async {
                    self.resultsCache[query] = .finished(results: results)
                    if searchController.searchBar.text == query {
                        // these results are relevant now!
                        self.results = results
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = self.results[indexPath.row].title
        return cell
    }
}
