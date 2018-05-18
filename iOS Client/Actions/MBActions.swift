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
    var shouldMakeNetworkCall: Bool
}

struct LoadedArticles: Action {
    var articles: Loaded<[MBArticle]>
}

struct SelectedArticle: Action {
    var article: MBArticle
}

struct ShowMoreArticles: Action {
    var topLevelCategory: String
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

struct LoadedPodcasts: Action {
    var podcasts: Loaded<[Podcast]>
}

struct SelectedPodcast: Action {
    var podcast: Podcast
}

struct PlayPausePodcast: Action {
}

struct FinishedPodcast: Action { }

struct PodcastError: Action { }

struct TogglePodcastFilter: Action {
    var podcastStream: PodcastStream
}

struct FilterPodcasts: Action { }

struct SetPodcastStreams: Action {
    var streams: [PodcastStream]
}
