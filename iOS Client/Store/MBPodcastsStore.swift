//
//  MBPodcastsStore.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import CoreData


class MBPodcastsStore {
    
    let client: MBClient
    let fileHelper: FileHelper
    var xmlParserDelegate: PodcastXMLParsingDelegate
    
    init() {
        client = MBClient()
        fileHelper = FileHelper()
        xmlParserDelegate = PodcastXMLParsingDelegate()
    }
    
    func syncPodcasts(completion: @escaping ([MBPodcast]?, Error?) -> Void) {
        self.client.getPodcastsWithCompletion { data, error in
            if error == nil {
                do {
                    // We got some data now parse
                    print("fetched podcasts from server")
                    let parser = XMLParser()
                    self.xmlParserDelegate = PodcastXMLParsingDelegate()
                    parser.delegate = self.xmlParserDelegate
                    parser.parse()
                    let podcasts = self.xmlParserDelegate.podcasts
                    try self.fileHelper.save(podcasts, forPath: "podcasts")
                    completion(podcasts, nil)
                } catch let error {
                    completion(nil, error)
                }
            } else {
                // Failed so complete with no devotions
                completion(nil, error)
            }
        }
    }
}
