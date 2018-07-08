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
        podcastsState: podcastsReducer(action: action, state: state?.podcastsState)
    )
}

func podcastsReducer(action: Action, state: PodcastsState?) -> PodcastsState {
    var nextState = state ?? MBPodcastsState()
    switch action {
    case let action as LoadedPodcasts:
        nextState.podcasts = action.podcasts
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
        if !action.toggle {
            nextState.visibleStreams.insert(action.podcastStream)
        } else {
            nextState.visibleStreams.remove(action.podcastStream)
        }
    case let action as SetPodcastStreams:
        nextState.streams = action.streams
        nextState.visibleStreams = Set<PodcastStream>(action.streams.map { $0 })
    case let action as DownloadPodcast:
        nextState.downloadingPodcasts.insert(action.title)
    case let action as FinishedDownloadingPodcast:
        nextState.downloadingPodcasts.remove(action.title)
        nextState.downloadedPodcasts.insert(action.title)
    case let action as SetDownloadedPodcasts:
        nextState.downloadedPodcasts = Set<String>(action.titles.map { $0 })
    default:
        break
    }
    return nextState
    
}
