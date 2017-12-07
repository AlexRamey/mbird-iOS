//
//  Routing.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/4/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import ReSwift

enum RouteComponent: Equatable {
    case base
    case detail(item: Detailable)
    
    static func == (lhs: RouteComponent, rhs: RouteComponent) -> Bool {
        if case .base = lhs, case .base = rhs {
            return true
        } else if case .detail = lhs, case .detail = rhs {
            return true
        } else {
            return false
        }
    }
 
    
    func viewController(forTab tab: Tab) -> UIViewController? {
        var retVal: UIViewController?
        
        switch tab {
        case .articles:
            if case .base = self {
                retVal = MBArticlesViewController.instantiateFromStoryboard(bookmarks: false)
            } else if case let .detail(detailItem) = self {
                retVal = MBArticleDetailViewController.instantiateFromStoryboard(article: detailItem as? MBArticle)
            }
        case .bookmarks:
            if case .base = self {
                retVal = MBArticlesViewController.instantiateFromStoryboard(bookmarks: true)
            }
        case .devotions:
            if case .base = self {
                retVal = MBDevotionsViewController.instantiateFromStoryboard()
            } else if case let .detail(detailItem) = self {
                retVal = DevotionDetailViewController.instantiateFromStoryboard()
            }
        }
        return retVal
    }
}

enum Tab: Int {
    case articles, bookmarks, devotions
}

protocol Detailable {
}
