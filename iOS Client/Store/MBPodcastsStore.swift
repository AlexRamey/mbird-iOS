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
        let d = DateFormatter()
        d.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return d
    }()
    
    let streams: [PodcastStream] = [.pz, .mockingPulpit, .mockingCast, .talkingbird]
    
    init() {
        client = MBClient()
        fileHelper = FileHelper()
    }
    
    func syncPodcasts() -> Promise<[Podcast]> {
        let requests = streams.map {self.client.getPodcasts(for: $0)}
        return firstly {
            when(resolved: requests)
        }.then { responses -> Promise<[Podcast]> in
            var podcasts: [Podcast] = []
            for (indx, response) in responses.enumerated() {
                if case .fulfilled(let newCasts) = response {
                    let displayCasts = newCasts.flatMap { podcast -> Podcast? in
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
            MBStore.sharedStore.dispatch(SetPodcastStreams(streams: [.pz, .mockingPulpit, .mockingCast, .talkingbird]))
            podcasts.sort(by: { $0.pubDate > $1.pubDate })
            return Promise(value: podcasts)
        }
    }
    
    func readPodcastFilterSettings() {
        streams.forEach {
            let streamSetting = UserDefaults.standard.bool(forKey: $0.title)
            print(streamSetting)
            MBStore.sharedStore.dispatch(TogglePodcastFilter(podcastStream: $0, toggle: streamSetting))
        }
    }
}
