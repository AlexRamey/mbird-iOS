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
    enum FileHelperError: Error {
        case readError(msg: String)
        case writeError(msg: String)
        case parseError(msg: String)
        case urlError(msg: String)
    }
    
    func read<T: Codable>(fromPath path: String, _ resource: T.Type) throws -> T {
        let (manager, path, _) = try urlPackage(forPath: path)
        if let data = manager.contents(atPath: path) {
            return try parse(data, T.self)
        } else {
            throw FileHelperError.readError(msg: "No data could be read from file \(path)")
        }
    }
    
    func urlPackage(forPath: String) throws -> (FileManager, String, URL) {
        let manager = FileManager.default
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first as URL? else {
            throw FileHelperError.urlError(msg: "Could not create path")
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
            throw FileHelperError.parseError(msg: "Could not read devotions from documents")
        }
    }
    
    func saveJSON<T: Encodable>(_ data: T, forPath path: String) throws {
        do {
            let (_, _, pathUrl) = try self.urlPackage(forPath: path)
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(data)
            try save(encodedData, url: pathUrl, options: [.atomic])
        } catch {
            throw FileHelperError.writeError(msg: "Could not save devotions to documents directory")
        }
    }
    
    func save(_ data: Data, url: URL, options: Data.WritingOptions) throws {
        try data.write(to: url, options: options)
    }
    
    
    
    func fileExists(at path: String) throws -> Bool {
        do {
            let (manager, path, _) = try urlPackage(forPath: path)
            return manager.fileExists(atPath: path)
        } catch {
            throw FileHelperError.readError(msg: "Could not check if a file exists at path \(path)")
        }
    }
    
    func createDirectory(at path: String) throws {
        do {
            let (manager, path, url) = try urlPackage(forPath: path)
            try manager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        } catch {
            throw FileHelperError.readError(msg: "Could not check if a file exists at path \(path)")
        }
    }
    
    func getPathsAtDirectory(directory: String) -> [String] {
        do {
            let (manager, filePath, _) = try urlPackage(forPath: directory)
            let paths = try manager.subpathsOfDirectory(atPath: filePath)
            return paths
        } catch {
            return []
        }
    }
}
