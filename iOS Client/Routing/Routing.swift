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
    case action
    case more
    
    static func == (lhs: RouteComponent, rhs: RouteComponent) -> Bool {
        if case .base = lhs, case .base = rhs {
            return true
        } else if case .detail = lhs, case .detail = rhs {
            return true
        } else if case .action = lhs, case .action = rhs {
            return true
        } else if case .more = lhs, case .more = rhs {
            return true
        } else {
            return false
        }
    }
 
    
    func viewController(forTab tab: Tab, dependency: ArticleDAO?) -> UIViewController? {
        var retVal: UIViewController?
        
        switch tab {
        case .articles:
            if case .base = self {
                retVal = MBArticlesViewController.instantiateFromStoryboard()
            } else if case let .detail(detailItem) = self {
                retVal = MBArticleDetailViewController.instantiateFromStoryboard(article: detailItem as? Article, dao: dependency)
            } else if case .more = self {
                retVal = ShowMoreViewController.instantiateFromStoryboard()
            }
        case .bookmarks:
            if case .base = self {
                retVal = MBBookmarksViewController.instantiateFromStoryboard()
            } else if case let .detail(detailItem) = self {
                retVal = MBArticleDetailViewController.instantiateFromStoryboard(article: detailItem as? Article, dao: dependency)
            }
        case .devotions:
            if case .base = self {
                retVal = MBDevotionsViewController.instantiateFromStoryboard()
            } else if case .detail(_) = self {
                retVal = DevotionDetailViewController.instantiateFromStoryboard()
            }
        case .podcasts:
            if case .base = self {
                retVal = MBPodcastsViewController.instantiateFromStoryboard()
            } else if case .detail(_) = self {
                retVal = PodcastDetailViewController.instantiateFromStoryboard()
            } else if case .action = self {
                retVal = PodcastsFilterViewController.instantiateFromStoryboard()
            }
        }
        return retVal
    }
}

enum Tab: Int {
    case articles, bookmarks, devotions, podcasts
}

protocol Detailable {
}
