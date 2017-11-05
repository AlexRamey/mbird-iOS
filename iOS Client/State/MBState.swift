//
//  AppState.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

/********** Navigation State **********/
protocol TabBarState {
    var tabIndex: Int { get set }
}

protocol TabOneNavControllerState {
    var topControllerID: String { get set }
}

protocol NavigationState {
    var routes: [Tab: [RouteComponent]] { get set }
    var selectedTab: Tab { get set }
    var safariOverlays: [Tab: URL?] { get set }
}

struct MBNavigationState: NavigationState {
    var routes: [Tab: [RouteComponent]] = [.articles: [.base], .bookmarks: [.base]]
    var selectedTab: Tab = .articles
    var safariOverlays: [Tab: URL?] = [.articles: nil, .bookmarks: nil]
}
/**************************************/

/********** Article State *************/
protocol ArticleState {
    var articles: Loaded<[MBArticle]> { get set }
    var selectedArticle: MBArticle? { get set }
}
struct MBArticleState: ArticleState {
    var articles: Loaded<[MBArticle]> = .initial
    var selectedArticle: MBArticle? = nil
    
}
/**************************************/

/********** App State *************/
protocol AppState: StateType {
    var navigationState: NavigationState { get }
    var articleState: ArticleState { get }
    
    init(navigationState: NavigationState, articleState: ArticleState)
}

struct MBAppState: AppState {
    var navigationState: NavigationState = MBNavigationState()
    var articleState: ArticleState = MBArticleState()
    
    init(navigationState: NavigationState, articleState: ArticleState) {
        self.navigationState = navigationState
        self.articleState = articleState
    }
}
/**************************************/

/********* Loaded *************/
enum Loaded<T> {
    case initial
    case loading
    case loaded(data: T)
    case error
}

