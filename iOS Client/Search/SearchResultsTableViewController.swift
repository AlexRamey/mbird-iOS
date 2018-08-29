//
//  SearchResultsTableViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit
import Nuke
import Preheat

class SearchResultsTableViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    let reuseIdentifier = "searchResultCellReuseIdentifier"
    var searchBar: UISearchBar?
    var authorDAO: AuthorDAO!
    var categoryDAO: CategoryDAO!
    var debouncedSearch: Debouncer!
    weak var delegate: ArticlesTableViewDelegate?
    
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UITableView>?
    
    enum SearchOperation {
        case inProgress
        case finished(results: [Article])
    }
    
    var results: [Article] = []
    var resultsCache: [String: SearchOperation] = [:]
    
    // dependencies
    let client = MBClient()
    
    static func instantiateFromStoryboard(authorDAO: AuthorDAO, categoryDAO: CategoryDAO) -> SearchResultsTableViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticleSearchResultsVC") as! SearchResultsTableViewController
        // swiftlint:enable force_cast
        vc.debouncedSearch = Debouncer(delay: 1.0, callback: { (searchController) in
            DispatchQueue.main.async {
                vc.doSearch(for: searchController)
            }
        })
        vc.authorDAO = authorDAO
        vc.categoryDAO = categoryDAO
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension

        self.tableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        if let searchBar = self.searchBar {
            self.automaticallyAdjustsScrollViewInsets = false
            self.tableView.contentInset = UIEdgeInsets(top: searchBar.frame.size.height, left: 0.0, bottom: 0.0, right: 0.0)
            print("CURIOUS GEORGE: \(searchBar.frame.size.height)")
        }
        
        controller = Preheat.Controller(view: self.tableView)
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillAppear(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            self.tableView.contentInset.bottom = keyboardFrame.cgRectValue.height
        }
    }
    
    @objc func keyboardWillDisappear() {
        UIView.animate(withDuration: 0.5) {
            self.tableView.contentInset.bottom = 0.0
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.compactMap({ (indexPath) -> Request? in
                guard self.results.count > indexPath.row else {
                    return nil
                }
                let article = self.results[indexPath.row]
                if let url = article.image?.thumbnailUrl {
                    var request = Request(url: url)
                    request.priority = .low
                    return request
                }
                return nil
            })
        }
        
        preheater.startPreheating(with: requests(for: added))
        preheater.stopPreheating(with: requests(for: removed))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        controller?.enabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        controller?.enabled = false
    }
    
    func doSearch(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, query != "" else {
            self.setResults([])
            self.tableView.backgroundView = nil
            return
        }
        
        // serve from cache if possible
        if let operation = self.resultsCache[query] {
            switch operation {
            case .inProgress:
                // don't issue a request if one is currently outstanding
                return
            case .finished(let articles):
                self.setResults(articles)
                return
            }
        }
        
        self.spinner.startAnimating()
        // issue a query to the search API
        self.client.searchArticlesWithCompletion(query: query) { (articles, err) in
            if let err = err {
                DispatchQueue.main.async {
                    print("SEARCH ERROR: \(err.localizedDescription)")
                    if searchController.searchBar.text == query {
                        // these are the relevant results
                        self.setResults([])
                    }
                }
                return
            }
            
            var results = articles
            for index in 0..<results.count {
                results[index].resolveAuthor(dao: self.authorDAO)
                results[index].resolveCategories(dao: self.categoryDAO)
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
                        self.setResults(results)
                    }
                }
            })
        }
    }
    
    private func setResults(_ results: [Article]) {
        self.spinner.stopAnimating()
        self.results = results
        self.tableView.reloadData()
        if self.results.count == 0 {
            let screenWidth = UIScreen.main.bounds.width
            let noResultsLabel = UILabel()
            noResultsLabel.textAlignment = .center
            noResultsLabel.font = UIFont(name: "IowanOldStyle-Bold", size: 24.0)
            noResultsLabel.text = "no search results"
            self.tableView.backgroundView = noResultsLabel
        } else {
            self.tableView.backgroundView = nil
        }
    }
    
    // MARK: - UI Search Results Updating
    func updateSearchResults(for searchController: UISearchController) {
        self.debouncedSearch.call(searchController: searchController)
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? SearchResultTableViewCell else {
            return UITableViewCell()
        }

        // Configure the cell...
        let article = self.results[indexPath.row]
        cell.setTitle(article.title.convertHtml())
        cell.thumbnailImage.image = nil
        if let url = article.image?.thumbnailUrl {
            Manager.shared.loadImage(with: url, into: cell.thumbnailImage)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = self.delegate {
            delegate.selectedArticle(self.results[indexPath.row], categoryContext: nil)
        }
    }
}
