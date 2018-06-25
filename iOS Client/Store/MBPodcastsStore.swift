//
//  MBPodcastsStore.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit


class MBPodcastsStore {
    
    let client: MBClient
    let fileHelper: FileHelper
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    let streams: [PodcastStream] = [.pz, .mockingPulpit, .mockingCast, .talkingbird]
    var podcastsPath: String = "podcasts.json"
    var podcastsDirectory: String = "podcasts"
    
    init() {
        client = MBClient()
        fileHelper = FileHelper()
        initializeFiles()
        MBStore.sharedStore.dispatch(SetPodcastStreams(streams: streams))
    }
    
    func syncPodcasts() -> Promise<[Podcast]> {
        let requests = streams.map {self.client.getPodcasts(for: $0)}
        return firstly {
            when(resolved: requests)
        }.then { responses -> Promise<[Podcast]> in
            var podcasts: [Podcast] = []
            var successfulResponses = 0
            for (indx, response) in responses.enumerated() {
                if case .fulfilled(let newCasts) = response {
                    successfulResponses += 1
                    let displayCasts = newCasts.compactMap { podcast -> Podcast? in
                        guard let dateString = podcast.pubDate?.replacingOccurrences(of: "EDT", with: "-0500"), let date = self.dateFormatter.date(from: dateString) else {
                            return nil
                        }
                        return Podcast(author: podcast.author,
                                                  duration: podcast.duration,
                                                  guid: podcast.guid,
                                                  image: self.streams[indx].imageName,
                                                  keywords: podcast.keywords,
                                                  summary: podcast.summary,
                                                  pubDate: date,
                                                  title: podcast.title,
                                                  feed: self.streams[indx] )
                    }
                    podcasts.append(contentsOf: displayCasts)
                }
            }
            guard successfulResponses > 0 else {
                throw PodcastStoreError.networkError
            }
            podcasts.sort(by: { $0.pubDate > $1.pubDate })
            return Promise(value: podcasts)
        }.then { podcasts -> Promise<[Podcast]> in
            self.savePodcasts(podcasts: podcasts).then { return Promise(value: podcasts) }
        }
    }
    
    func savePodcasts(podcasts: [Podcast]) -> Promise<Void> {
        return firstly {
           try fileHelper.saveJSON(podcasts, forPath: podcastsPath)
            return Promise()
        }
    }
    
    func getSavedPodcasts() -> Promise<[Podcast]> {
        return firstly {
            let podcasts = try fileHelper.read(fromPath: podcastsPath, [Podcast].self)
            return Promise(value: podcasts)
        }
    }
    
    func initializeFiles() {
        do {
            let hasData = try fileHelper.fileExists(at: podcastsPath)
            if !hasData {
                let empty: [Podcast] = []
                try fileHelper.saveJSON(empty, forPath: podcastsPath)
            }
            let hasPodcastDirectory = try fileHelper.fileExists(at: podcastsDirectory)
            if !hasPodcastDirectory {
                try fileHelper.createDirectory(at: podcastsDirectory)
            }
        } catch {
            print("could not initialize podcasts files")
        }
    }
    
    func readPodcastFilterSettings() {
        streams.forEach {
            let streamSetting = UserDefaults.standard.bool(forKey: $0.title)
            print(streamSetting)
            MBStore.sharedStore.dispatch(TogglePodcastFilter(podcastStream: $0, toggle: streamSetting))
        }
    }
    
    func conatainsSavedPodcast(_ podcast: Podcast) -> Bool {
        guard let title = podcast.title else { return false }
        do {
            let isFilePresent = try fileHelper.fileExists(at: "podcasts/\(title).mp3")
            return isFilePresent
        } catch { }
        return false
    }
    
    func getUrlFor(podcast: Podcast) -> URL? {
        do {
            if let title = podcast.title {
                let (_, _, url) = try fileHelper.urlPackage(forPath: "podcasts/\(title).mp3")
                return url
            }
        } catch { }
        return nil
        
    }
    
    func savePodcastData(data: Data, path: String) {
        do {
            let (_, _, url) = try fileHelper.urlPackage(forPath: "podcasts/\(path).mp3")
            try fileHelper.save(data, url: url, options: [.atomic])
        } catch let error {
            print("error saving podcast data")
        }
    }
    
    func getSavedPodcastsTitles() -> [String] {
        return fileHelper.getPathsAtDirectory(directory: podcastsDirectory).compactMap {
            return String($0.prefix($0.count-4))
        }
    }
}

enum PodcastStoreError: Error {
    case networkError
}
