//
//  MBReducer.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

func appReducer(action: Action, state: MBAppState?) -> MBAppState {
    return MBAppState(
        navigationState: navigationReducer(action: action, state: state?.navigationState),
        articleState: articleReducer(action: action, state: state?.articleState),
        devotionState: devotionReducer(action: action, state: state?.devotionState)
    )
}

func navigationReducer(action: Action, state: NavigationState?) -> NavigationState {
    var nextState = state ?? MBNavigationState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    case let action as NavigationActionSwitchTab:
        nextState.selectedTab = action.tab
    case let action as SelectedArticle:
        nextState.routes[.articles]?.append(.detail(item: action.article))
    case let action as SelectedArticleLink:
        nextState.safariOverlays[.articles] = action.url
    case _ as PopCurrentNavigation:
        nextState.routes[nextState.selectedTab]?.removeLast()
    default:
        break
    }
    
    return nextState
}

func articleReducer(action: Action, state: ArticleState?) -> ArticleState {
    var nextState = state ?? MBArticleState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    case let action as LoadedArticles:
        nextState.articles = action.articles
    case let action as SelectedArticle:
        nextState.selectedArticle = action.article
    default:
        break
    }
    
    return nextState
}

func devotionReducer(action: Action, state: DevotionState?) -> DevotionState {
    var nextState = state ?? MBDevotionState()
    switch action {
    case let action as LoadedDevotions:
        nextState.devotions = action.devotions
    default:
        break
    }
    return nextState
}
