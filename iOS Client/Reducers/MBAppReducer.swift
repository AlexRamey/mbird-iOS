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
    case _ as ShowMoreArticles:
        nextState.routes[nextState.selectedTab]?.append(.more)
    case let action as SelectedDevotion:
        nextState.selectedTab = .devotions
        nextState.routes[.devotions]?.append(.detail(item: action.devotion))
    case let action as SelectedArticleLink:
        nextState.safariOverlays[nextState.selectedTab] = action.url
    case let action as SelectedPodcast:
        nextState.routes[.podcasts]?.append(.detail(item: action.podcast))
    case _ as PopCurrentNavigation:
        print("Popping from \(nextState.selectedTab)")
        nextState.routes[nextState.selectedTab]?.removeLast()
    case _ as FilterPodcasts:
        nextState.routes[.podcasts]?.append(.action)
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
    case _ as RefreshArticles:
        nextState.articles = Loaded<[MBArticle]>.loading
    case let action as LoadedArticles:
        nextState.articles = action.articles
    case let action as SelectedArticle:
        nextState.selectedArticle = action.article
    case let action as ShowMoreArticles:
        nextState.selectedCategory = action.topLevelCategory
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
    default:
        break
    }
    return nextState
}

func podcastsReducer(action: Action, state: PodcastsState?) -> PodcastsState {
    var nextState = state ?? MBPodcastsState()
    switch action {
    case let action as LoadedPodcasts:
        nextState.podcasts = action.podcasts
    case let action as SelectedPodcast:
        nextState.selectedPodcast = action.podcast
        nextState.player = .playing
    case _ as FinishedPodcast:
        nextState.player = .finished
    case _ as PodcastError:
        nextState.player = .error
    case _ as PlayPausePodcast:
        if nextState.player == .playing {
            nextState.player = .paused
        } else {
            nextState.player = .playing
        }
    case let action as TogglePodcastFilter:
        if state?.visibleStreams.contains(action.podcastStream) ?? false {
            nextState.visibleStreams.remove(action.podcastStream)
        } else {
            nextState.visibleStreams.insert(action.podcastStream)
        }
    case let action as SetPodcastStreams:
        nextState.streams = action.streams
        nextState.visibleStreams = Set<PodcastStream>(action.streams.map { $0 })
    default:
        break
    }
    return nextState
    
}

func settingsReducer(action: Action, state: SettingsState?) -> SettingsState {
    let nextState = state ?? MBSettingsState()
    return nextState
}
