//
//  MBActions.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

struct NavigationActionSwitchTab: Action {
    var tab: Tab
}

struct PushRoute: Action {
    var route: RouteComponent
}

struct RefreshArticles: Action {
}

struct LoadedArticles: Action {
    var articles: Loaded<[MBArticle]>
}

struct SelectedArticle: Action {
    var article: MBArticle
}

struct PopCurrentNavigation: Action {
}


struct LoadedDevotions: Action {
    var devotions: Loaded<[LoadedDevotion]>
}

struct SelectedArticleLink: Action {
    var url: URL?
}

struct SelectedDevotion: Action {
    var devotion: LoadedDevotion
}

struct UnreadDevotion: Action {
    var devotion: LoadedDevotion
}

struct LoadedPodcasts: Action {
    var podcasts: Loaded<[DisplayablePodcast]>
}

struct SelectedPodcast: Action {
    var podcast: DisplayablePodcast
}

struct PlayPausePodcast: Action {
}

struct FinishedPodcast: Action { }

struct PodcastError: Action { }
