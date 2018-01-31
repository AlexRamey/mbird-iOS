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
    
    init() {
        client = MBClient()
        fileHelper = FileHelper()
    }
    
    func syncPodcasts() -> Promise<[DisplayablePodcast]> {
        let streams: [MBClient.PodcastStream] = [.pz, .mockingPulpit, .mockingCast]
        let requests = streams.map{ self.client.getPodcasts(for: $0)}
        return firstly {
            when(resolved: requests)
        }.then { responses -> Promise<[DisplayablePodcast]> in
            var podcasts: [DisplayablePodcast] = []
            for (indx, response) in responses.enumerated() {
                if case .fulfilled(let newCasts) = response {
                    let displayCasts = newCasts.flatMap { podcast -> DisplayablePodcast? in
                        guard let dateString = podcast.pubDate, let date = self.dateFormatter.date(from: dateString) else {
                            return nil
                        }
                        return DisplayablePodcast(author: podcast.author,
                                                  duration: podcast.duration,
                                                  guid: podcast.guid,
                                                  image: streams[indx].imageName,
                                                  keywords: podcast.keywords,
                                                  summary: podcast.summary,
                                                  pubDate: date,
                                                  title: podcast.title)
                    }
                    podcasts.append(contentsOf: displayCasts)
                }
            }
            podcasts.sort(by: { $0.pubDate > $1.pubDate })
            return Promise(value: podcasts)
        }
    }
}
