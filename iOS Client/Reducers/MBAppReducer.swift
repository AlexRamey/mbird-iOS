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
        devotionState: devotionReducer(action: action, state: state?.devotionState),
        podcastsState: podcastsReducer(action: action, state: state?.podcastsState),
        settingsState: settingsReducer(action: action, state: state?.settingsState)
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
        nextState.routes[nextState.selectedTab]?.append(.detail(item: action.article))
    case let action as SelectedDevotion:
        nextState.selectedTab = .devotions
        nextState.routes[.devotions]?.append(.detail(item: action.devotion))
    case let action as SelectedArticleLink:
        nextState.safariOverlays[nextState.selectedTab] = action.url
    case let action as SelectedPodcast:
        nextState.routes[.podcasts]?.append(.detail(item: action.podcast))
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
    case let action as RefreshArticles:
        nextState.articles = Loaded<[MBArticle]>.loading
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
    case let action as SelectedDevotion:
        nextState.selectedDevotion = action.devotion
        nextState.mark(devotion: action.devotion, asRead: true)
    case let action as UnreadDevotion:
        nextState.mark(devotion: action.devotion, asRead: false)
    default:
        break
    }
    return nextState
}

func podcastsReducer(action: Action, state: PodcastsState?) -> PodcastsState {
    var nextState = state ?? MBPodcastsState()
    switch action{
    case let action as LoadedPodcasts:
        nextState.podcasts = action.podcasts
    case let action as SelectedPodcast:
        nextState.selectedPodcast = action.podcast
        nextState.player = .playing
    case let action as FinishedPodcast:
        nextState.player = .finished
    case let action as PodcastError:
        nextState.player = .error
    case let action as PlayPausePodcast:
        if nextState.player == .playing {
            nextState.player = .paused
        } else {
            nextState.player = .playing
        }
    default:
        break
    }
    return nextState
    
}

func settingsReducer(action: Action, state: SettingsState?) -> SettingsState {
    var nextState = state ?? MBSettingsState()
    return nextState
}
