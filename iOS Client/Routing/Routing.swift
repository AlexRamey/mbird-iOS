//
//  Routing.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/4/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import ReSwift

enum Route: Equatable {
    
    case base
    case detail(item: Detailable)
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        if case .base = lhs, case .base = rhs {
            return true
        } else if case .detail = lhs, case .detail = rhs {
            return true
        } else {
            return false
        }
    }
 
    
    static func viewController(forRoute route: Route, inTab tab: Tab) -> UIViewController? {
        switch tab {
        case .articles:
            if case .base = route {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as? MBArticlesViewController {
                    return vc
                }
            }
        case .bookmarks:
            if case .base = route {
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BookmarksController") as? MBBookmarksViewController {
                    return vc
                }
            }
        }
        return nil
    }
}

enum Tab: Int {
    case articles = 0
    case bookmarks = 1
    
    static func tab(forViewController viewController: UIViewController) -> Tab? {
        if viewController is MBArticlesViewController {
            return .articles
        } else if viewController is MBBookmarksViewController {
            return .bookmarks
        } else {
            return nil
        }
    }
    
    static func tab(forCoordinator coordinator: Coordinator) -> Tab? {
        if coordinator is ArticlesCoordinator {
            return .articles
        } else if coordinator is BookmarksCoordinator {
            return .bookmarks
        } else {
            return nil
        }
    }
    
    
}

protocol Detailable {
}
