//
//  Store.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift
import CoreData

class MBStore: NSObject {
    static let sharedStore = Store(
        reducer: appReducer,
        state: nil,
        middleware: [MiddlewareFactory.loggingMiddleware])      // Middlewares are optional
    
    func syncPodcasts(persistentContainer: NSPersistentContainer, completion: @escaping (Bool?, Error?) -> Void) {
        self.downloadPodcasts(persistentContainer: persistentContainer, completion: { (isNewPodcastData, podcastErr) in
            if let err = podcastErr {
                print("There was an error downloading podcast data! \(err)")
                completion(nil, err)
            } else {
                completion(isNewPodcastData, nil)
            }
        })
    }
}

enum SerializationType {
    case json
    case xml
}
