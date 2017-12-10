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
    
    override init() {
        client = MBClient()
        super.init()
    }
    
    // nested store error enumeration
    enum StoreError: Error {
        case readError(msg: String)
        case writeError(msg: String)
        case parseError(msg: String)
        case urlError(msg: String)
    }
    
    func getDevotions() -> [LoadedDevotion] {
        do {
            return try read(fromPath: "devotions", [LoadedDevotion].self)
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
                    let devotions = try self.parse(data, [MBDevotion].self)
                    let loadedDevotions = devotions.map {LoadedDevotion(devotion: $0, read: false)}
                    try self.save(loadedDevotions, forPath: "devotions")
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
        try self.save(devotions, forPath: "devotions")
    }
    
    func replace(devotion: LoadedDevotion) throws {
        let devotions = try self.read(fromPath: "devotions", [LoadedDevotion].self)
        let markedDevotions = devotions.map { oldDevotion in
            oldDevotion.date == devotion.date ? devotion : oldDevotion
        }
        try self.save(markedDevotions, forPath: "devotions")
    }
    
    private func read<T: Codable>(fromPath path: String, _ resource: T.Type) throws -> T {
        let (manager, path, _) = try urlPackage(forPath: path)
        if let data = manager.contents(atPath: path) {
            return try parse(data, T.self)
        } else {
            throw StoreError.readError(msg: "No data could be read from file \(path)")
        }
    }
    
    private func urlPackage(forPath: String) throws -> (FileManager, String, URL) {
        let manager = FileManager.default
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first as URL? else {
            throw StoreError.urlError(msg: "Could not create path")
        }
        let path = url.path.appending("/\(forPath)")
        let pathUrl = URL(fileURLWithPath: path)
        return (manager, path, pathUrl)
    }
    
    private func parse<T: Codable>(_ data: Data, _ resource: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            let models = try decoder.decode(T.self, from: data)
            return models
        } catch {
            throw StoreError.parseError(msg: "Could not read devotions from documents")
        }
    }
    
    private func save<T: Encodable>(_ data: T, forPath path: String) throws {
        do {
            let (_, _, pathUrl) = try self.urlPackage(forPath: path)
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: pathUrl, options: [.atomic])
        } catch {
            throw StoreError.writeError(msg: "Could not save devotions to documents directory")
        }
    }
}
