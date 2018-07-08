//
//  MBActions.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

struct LoadedPodcasts: Action {
    var podcasts: Loaded<[Podcast]>
}

struct PlayPausePodcast: Action {
}

struct FinishedPodcast: Action { }

struct PodcastError: Action { }

struct TogglePodcastFilter: Action {
    var podcastStream: PodcastStream
    var toggle: Bool
}

struct FilterPodcasts: Action { }

struct SetPodcastStreams: Action {
    var streams: [PodcastStream]
}

struct DownloadPodcast: Action {
    var title: String
}

struct FinishedDownloadingPodcast: Action {
    var title: String
}

struct SetDownloadedPodcasts: Action {
    var titles: [String]
}
