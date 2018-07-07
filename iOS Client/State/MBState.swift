//
//  AppState.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

/********** Article State *************/
protocol ArticleState {
    var articles: Loaded<[MBArticle]> { get set }
}
struct MBArticleState: ArticleState {
    var articles: Loaded<[MBArticle]> = .initial
    
}
/**************************************/

/********** Devotion State *************/
protocol DevotionState {
    var devotions: Loaded<[LoadedDevotion]> { get set }
}
struct MBDevotionState: DevotionState {
    var devotions: Loaded<[LoadedDevotion]> = .initial
}
/**************************************/

/********** Podcasts State *************/
protocol PodcastsState {
    var podcasts: Loaded<[Podcast]> { get set }
    var player: PlayerState { get set }
    var streams: [PodcastStream] { get set }
    var visibleStreams: Set<PodcastStream> { get set }
    var downloadingPodcasts: Set<String> { get set }
    var downloadedPodcasts: Set<String> { get set }
}

struct MBPodcastsState: PodcastsState {
    var podcasts: Loaded<[Podcast]> = .initial
    var player: PlayerState = .initialized
    var visibleStreams: Set<PodcastStream> = Set<PodcastStream>()
    var streams: [PodcastStream] = []
    var downloadingPodcasts: Set<String> = Set<String>()
    var downloadedPodcasts: Set<String> = Set<String>()
}

/********** Settings State *************/
protocol SettingsState {
    var notificationPermission: Permission { get set }
}

struct MBSettingsState: SettingsState {
    var notificationPermission: Permission = .unprompted
}

/********** App State *************/
protocol AppState: StateType {
    var articleState: ArticleState { get }
    var devotionState: DevotionState { get }
    var podcastsState: PodcastsState { get }
    var settingsState: SettingsState { get }
    
    init(articleState: ArticleState, devotionState: DevotionState, podcastsState: PodcastsState, settingsState: SettingsState)
}

struct MBAppState: AppState {
    var articleState: ArticleState = MBArticleState()
    var devotionState: DevotionState = MBDevotionState()
    var podcastsState: PodcastsState = MBPodcastsState()
    var settingsState: SettingsState = MBSettingsState()
    
    init(articleState: ArticleState, devotionState: DevotionState, podcastsState: PodcastsState, settingsState: SettingsState) {
        self.articleState = articleState
        self.devotionState = devotionState
        self.podcastsState = podcastsState
        self.settingsState = settingsState
    }
}
/**************************************/

/********* Loaded *************/
enum Loaded<T> {
    case initial
    case loading
    case loadingFromDisk
    case loaded(data: T)
    case error
}

/****** Permission *****/
enum Permission {
    case unprompted
    case approved
    case denied
}

enum PlayerState {
    case initialized
    case playing
    case paused
    case error
    case finished
}
