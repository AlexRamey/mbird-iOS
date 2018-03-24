//
//  MBDevotionsStore.swift
//  iOS Client
//
//  Created by Alex Ramey on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation

class MBDevotionsStore: NSObject {
    private let client: MBClient
    private let fileHelper: FileHelper
    
    override init() {
        client = MBClient()
        fileHelper = FileHelper()
        super.init()
    }
    
    func getDevotions() -> [LoadedDevotion] {
        do {
            return try fileHelper.read(fromPath: "devotions", [LoadedDevotion].self)
        } catch {
            return []
        }
    }
    
    // New function for devotions until we figure out if this will have to go over network or can be stored locally
    func syncDevotions(completion: @escaping ([LoadedDevotion]?, Error?) -> Void) {
        self.client.getJSONFile(name: "devotions") { data, error in
            if error == nil, let data = data {
                do {
                    // We got some data now parse
                    print("fetched devotions from bundle")
                    let devotions = try self.fileHelper.parse(data, [MBDevotion].self)
                    let loadedDevotions = devotions.map {LoadedDevotion(devotion: $0, read: false)}
                    try self.fileHelper.save(loadedDevotions, forPath: "devotions")
                    completion(loadedDevotions, nil)
                } catch let error {
                    completion(nil, error)
                }
            } else {
                // Failed so complete with no devotions
                completion(nil, error)
            }
        }
    }
    
    func saveDevotions(devotions: [LoadedDevotion]) throws {
        try fileHelper.save(devotions, forPath: "devotions")
    }

    func replace(devotion: LoadedDevotion) throws {
        let devotions = try fileHelper.read(fromPath: "devotions", [LoadedDevotion].self)
        let markedDevotions = devotions.map { oldDevotion in
            oldDevotion.date == devotion.date ? devotion : oldDevotion
        }
        try fileHelper.save(markedDevotions, forPath: "devotions")
    }
}
