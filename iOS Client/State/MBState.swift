//
//  AppState.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

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

/********** App State *************/
protocol AppState: StateType {
    var podcastsState: PodcastsState { get }
    init(podcastsState: PodcastsState)
}

struct MBAppState: AppState {
    var podcastsState: PodcastsState = MBPodcastsState()
    init(podcastsState: PodcastsState) {
        self.podcastsState = podcastsState
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

enum PlayerState {
    case initialized
    case playing
    case paused
    case error
    case finished
}
