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
        articleState: articleReducer(action: action, state: state?.articleState)
    )
}

func navigationReducer(action: Action, state: NavigationState?) -> NavigationState {
    var nextState = state ?? MBNavigationState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    case let action as NavigationActionSwitchTab:
        nextState.tabIndex = action.newIndex
    default:
        break
    }
    
    return nextState
}

func articleReducer(action: Action, state: ArticleState?) -> ArticleState {
    let nextState = state ?? MBArticleState()
    
    switch action {
    case _ as ReSwiftInit:
        break
    default:
        break
    }
    
    return nextState
}
