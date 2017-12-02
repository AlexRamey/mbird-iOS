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
    
    private let client: MBClient
    
    override init() {
        client = MBClient()
        super.init()
    }
    
    /***** Read Data from Core Data (Only Invoke These From The Main Thread) *****/
    func getAuthors(persistentContainer: NSPersistentContainer) -> [MBAuthor] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName)
        return performFetch(managedContext: persistentContainer.viewContext, fetchRequest: fetchRequest) as? [MBAuthor] ?? []
    }
    
    func getCategories(persistentContainer: NSPersistentContainer) -> [MBCategory] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        return performFetch(managedContext: persistentContainer.viewContext, fetchRequest: fetchRequest) as? [MBCategory] ?? []
    }
    
    func getArticles(persistentContainer: NSPersistentContainer) -> [MBArticle] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        return performFetch(managedContext: persistentContainer.viewContext, fetchRequest: fetchRequest) as? [MBArticle] ?? []
    }
    
    private func performFetch(managedContext: NSManagedObjectContext, fetchRequest: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }
    

    /***** Download Data from Network (MAY BE INVOKED FROM ANY THREAD) *****/
    func syncAllData(persistentContainer: NSPersistentContainer, completion: @escaping (Bool?, Error?) -> Void) {
        var isNewData: Bool = false
        downloadAuthors(persistentContainer: persistentContainer) { (isNewAuthorData, authorsErr) in
            if let unwrappedAuthorsErr = authorsErr {
                print("There was an error downloading author data! \(unwrappedAuthorsErr)")
                completion(nil, authorsErr)
            } else {
                self.downloadCategories(persistentContainer: persistentContainer, completion: { (isNewCategoryData, catErr) in
                    if let unwrappedCatErr = catErr {
                        print("There was an error downloading category data! \(unwrappedCatErr)")
                        completion(nil, catErr)
                    } else {
                        self.downloadArticles(persistentContainer: persistentContainer, completion: { (isNewArticleData, articleErr) in
                            isNewData = isNewAuthorData ?? false || isNewCategoryData ?? false || isNewArticleData ?? false
                            if let unwrappedArticleErr = articleErr {
                                print("There was an error downloading article data! \(unwrappedArticleErr)")
                                completion(nil, articleErr)
                            } else {
                                completion(isNewData, nil)
                            }
                        })
                    }
                })
            }
        }
    }
    

    //New function for devotions until we figure out if this will have to go over network or can be stored locally
    func syncDevotions(completion: @escaping ([LoadedDevotion]?, Error?) -> Void) {
        do{
            //Try to get any previously saved devotions
            let devotions = try read(fromPath: "devotions", [LoadedDevotion].self)
            completion(devotions, nil)
        } catch {
            //If none in Documents file try to read from bundle
            self.client.getJSONFile(name: "devotions") { data, error in
                if error == nil, let data = data {
                    do{
                        //We got some data now parse
                        print("fetched devotions from bundle")
                        let devotions = try self.parse(data, [MBDevotion].self)
                        let loadedDevotions = devotions.map {LoadedDevotion(devotion: $0, read: false)}
                        try self.save(loadedDevotions, "devotions")
                        completion(loadedDevotions, nil)
                    } catch let error {
                        completion(nil, error)
                    }
                } else {
                    //Failed so complete with no devotions
                    completion(nil, error)
                }
            }
        }
    }
    
    private func downloadAuthors(persistentContainer: NSPersistentContainer, completion: @escaping (Bool?, Error?) -> Void) {
        performDownload(clientFunction: client.getAuthorsWithCompletion, persistentContainer: persistentContainer, deserializeFunc: MBAuthor.deserialize, completion: completion)
    }
    
    private func downloadCategories(persistentContainer: NSPersistentContainer, completion: @escaping (Bool?, Error?) -> Void) {
        performDownload(clientFunction: client.getCategoriesWithCompletion, persistentContainer: persistentContainer, deserializeFunc: MBCategory.deserialize, completion: completion)
    }
    
    private func downloadArticles(persistentContainer: NSPersistentContainer, completion: @escaping (Bool?, Error?) -> Void) {
        performDownload(clientFunction: client.getArticlesWithCompletion, persistentContainer: persistentContainer, deserializeFunc: MBArticle.deserialize, completion: completion)
    }
    
    func saveDevotions(devotions: [LoadedDevotion]) throws {
        try self.save(devotions, "devotions")
    }
    
    private func read<T: Codable>(fromPath: String, _ resource: T.Type) throws -> T {
        let (manager, path, _) = try urlPackage(forPath: "\(fromPath)")
        if let data = manager.contents(atPath: path) {
            return try parse(data, T.self)
        } else {
            throw StoreError.readError(msg: "No data could be read from file \(fromPath)")
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
    
    private func save<T: Encodable>(_ data: T, _ path: String) throws {
        do {
            let (_, _, pathUrl) = try self.urlPackage(forPath: path)
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: pathUrl, options: [.atomic])
        } catch {
            throw StoreError.writeError(msg: "Could not save devotions to documents directory")
        }
    }

    // An internal helper function to perform a download
    private func performDownload(clientFunction: (@escaping ([Data], Error?) -> Void) -> (),
                                 persistentContainer: NSPersistentContainer,
                                 deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool,
                                 completion: @escaping (Bool?, Error?) -> Void) {
        
        var newDataFlag: Bool = false
        clientFunction { (data: [Data], err: Error?) in
            if let clientErr = err {
                completion(false, clientErr)
                return
            }
            
            // This serialQueue enables us to be certain only to invoke the completion handler once
            // It also guards us from race conditions when writing to the numHandled variable
            let serialQueue = DispatchQueue(label: "syncpoint")
            var numHandled = 0
            var hasReturned = false
            
            // data is an array of Data, where each datum is a serialized array
            // thus, think of data as an array of arrays of objects
            for jsonData in data {
                do {
                    try self.downloadModelsHandler(persistentContainer: persistentContainer,
                                                   data: jsonData,
                                                   deserializeFunc: deserializeFunc,
                                                   completion: { (isNewData: Bool?, err: Error?) in
                        serialQueue.async {
                            if !hasReturned {
                                if err != nil {
                                    completion(nil, err)
                                    hasReturned = true
                                } else {
                                    if let isNewDataUnwrapped = isNewData, isNewDataUnwrapped == true {
                                        newDataFlag = true
                                    }
                                    numHandled += 1
                                    if numHandled == data.count {
                                        completion(newDataFlag, nil)
                                    }
                                }
                            }
                        }
                    })
                } catch {
                    serialQueue.async {
                        if !hasReturned {
                           completion(nil, error)
                           hasReturned = true
                        }
                    }
                }
            }
        }
    }
    
    // An internal helper that returns a handler which saves the json array as a group of core data objects
    private func downloadModelsHandler(persistentContainer: NSPersistentContainer,
                                       data: Data,
                                       deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool,
                                       completion: @escaping (Bool?, Error?) -> Void) throws {
        
        var json : Any
        var isNewData: Bool = false

        // deserialize data into the managed context and save it
        json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        if let arr = json as? [NSDictionary] {
            persistentContainer.performBackgroundTask({ (managedContext) in
                do {
                    managedContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                    try arr.forEach({ (json: NSDictionary) in
                        if try deserializeFunc(json, managedContext) {
                            isNewData = true
                        }
                    })
                    
                    try managedContext.save()
                    
                    completion(isNewData, nil)
                } catch {
                    completion(nil, error)
                }
            })
        } else {
            throw MBDeserializationError.contractMismatch(msg: "unable to cast json object into an array of NSDictionary objects")
        }
    }
}

enum StoreError: Error {
    case readError(msg: String)
    case writeError(msg: String)
    case parseError(msg: String)
    case urlError(msg: String)
}
