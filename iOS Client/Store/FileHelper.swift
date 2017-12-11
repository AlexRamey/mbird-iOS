//
//  FileHelper.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation


class FileHelper {
    
    // nested store error enumeration
    enum StoreError: Error {
        case readError(msg: String)
        case writeError(msg: String)
        case parseError(msg: String)
        case urlError(msg: String)
    }
    
    func replace(devotion: LoadedDevotion) throws {
        let devotions = try self.read(fromPath: "devotions", [LoadedDevotion].self)
        let markedDevotions = devotions.map { oldDevotion in
            oldDevotion.date == devotion.date ? devotion : oldDevotion
        }
        try self.save(markedDevotions, forPath: "devotions")
    }
    
    func read<T: Codable>(fromPath path: String, _ resource: T.Type) throws -> T {
        let (manager, path, _) = try urlPackage(forPath: path)
        if let data = manager.contents(atPath: path) {
            return try parse(data, T.self)
        } else {
            throw StoreError.readError(msg: "No data could be read from file \(path)")
        }
    }
    
    func urlPackage(forPath: String) throws -> (FileManager, String, URL) {
        let manager = FileManager.default
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first as URL? else {
            throw StoreError.urlError(msg: "Could not create path")
        }
        let path = url.path.appending("/\(forPath)")
        let pathUrl = URL(fileURLWithPath: path)
        return (manager, path, pathUrl)
    }
    
    func parse<T: Codable>(_ data: Data, _ resource: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            let models = try decoder.decode(T.self, from: data)
            return models
        } catch {
            throw StoreError.parseError(msg: "Could not read devotions from documents")
        }
    }
    
    func save<T: Encodable>(_ data: T, forPath path: String) throws {
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

