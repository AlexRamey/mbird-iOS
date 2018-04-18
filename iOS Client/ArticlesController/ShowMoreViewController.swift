//
//  ShowMoreViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 4/16/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import CoreData
import UIKit
import PromiseKit
import ReSwift

class ShowMoreViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = ArticleState
    var articlesStore: MBArticlesStore?
    var currentCategory: MBCategory?
    var articles: [MBArticle] = []
    
    static func instantiateFromStoryboard() -> ShowMoreViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShowMoreViewController") as! ShowMoreViewController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureBackButton()
        
        // this is regrettable, but our routing setup makes it very cumbersome
        // to pass in dependencies for non-root view controllers. Ideally,
        // we would delete ReSwift and all routing logic, and just have the coordinators
        // respond to navigation events via delegate methods and inject dependencies
        // directly into newly spawned view controllers
        if let articlesVC = self.navigationController?.viewControllers.first as? MBArticlesViewController, self.articlesStore == nil {
            self.articlesStore = articlesVC.articlesStore
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MBStore.sharedStore.subscribe(self) {
            $0.select { appState in
                appState.articleState
            }.skipRepeats { lhs, rhs in
                lhs.selectedCategory == rhs.selectedCategory
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MBStore.sharedStore.unsubscribe(self)
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToArticles(sender:)))
    }
    
    @objc func backToArticles(sender: AnyObject) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    
    func newState(state: ArticleState) {
        if self.currentCategory?.name != state.selectedCategory {
            if let categoryName = state.selectedCategory {
                self.currentCategory = articlesStore?.getCategoryByName(categoryName)
            } else {
                self.currentCategory = nil
            }
            self.reloadArticles()
        }
    }
    
    private func reloadArticles() {
        guard let store = self.articlesStore, let cat = self.currentCategory else { return }
        
        var ids: [Int] = []
        var catArticles: Set<MBArticle> = []
        // DFS through the category tree rooted at currentCategory
        // to acquire the ids of all children categories
        var stack: [MBCategory] = [cat]
        while let current = stack.popLast() {
            ids.append(Int(current.categoryID))
            if let articles = current.articles as? Set<MBArticle> {
                catArticles.formUnion(articles)
            }
            if let children = current.children?.allObjects as? [MBCategory] {
                stack.append(contentsOf: children)
            }
        }
        
        // 1. Load articles we already have into the table view (catArticles)
        // 2. Fetch more articles in the given categories (ids) excluding catArticles.MapToIDs
        // ------> Change the implementation to only fetch 20 - excluded count
        // 3. Fetch all relevant category articles from core data and reload table view again
//        firstly {
//            store.syncCategoryArticles(categories: ids, excluded: catA)
//        }
        
        print("reloading!")
    }
}
