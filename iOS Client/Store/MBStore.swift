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
        //Try to get any previously saved devotions
        read(fromPath: "devotions", [LoadedDevotion].self) { (devotions, error) in
            if error == nil, let devotions = devotions { //success
                let regDevotions = devotions.map { $0.devotion }
                self.syncDevotionsWithReadDates(devotions: regDevotions, completion: completion)
                print("Fetched devotions from documents")
            } else {
                //If none in Documents file try to read from bundle
                self.client.getJSONFile(name: "devotions") { data, error in
                    if error == nil, let data = data {
                        //We got some data now parse
                        print("fetched devotions from bundle")
                        self.parse(data, [MBDevotion].self) { devotions, error in
                            if error == nil, let devotions = devotions {
                                //We got devotion objects now sync with read dates (if any) and save
                                self.syncDevotionsWithReadDates(devotions: devotions, completion: completion)
                            } else {
                                //Failed so complete with no devotions
                                completion(nil, error)
                            }
                        }
                    } else {
                        //Failed so complete with no devotions
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    private func syncDevotionsWithReadDates(devotions: [MBDevotion], completion: @escaping ([LoadedDevotion]?, Error?) -> Void) {
        //Try to get the list of dates
        self.read(fromPath: "readDevotionDates", [String].self) { (dates, error) in
            var loadedDevotions: [LoadedDevotion] = []
            
            if let dates = dates { //Success: so map to corresponding devotions
                loadedDevotions = devotions.map { devotion in
                    let read = dates.contains { $0 == devotion.date }
                    return LoadedDevotion(devotion: devotion, read: read)
                }
            } else { //Failure: so set all reads to false
                loadedDevotions = devotions.map { return LoadedDevotion(devotion: $0, read: false) }
            }
            
            //Now try to save these for future in the devotions directory
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(loadedDevotions)
                let (_, _, url) = try self.urlPackage(forPath: "devotions")
                self.save(data, url) { error in
                    completion(loadedDevotions, nil)
                }
            } catch {
                completion(loadedDevotions, nil)
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
    
    func markDevotionAsRead(date: String, completion: @escaping (Error?) -> Void) {
        //Get existing read dates
        read(fromPath: "readDevotionDates", [String].self) { dates, error in
            do {
                let (_, _, url) = try self.urlPackage(forPath: "readDevotionDates")
                var readDates: [String] = []
                if error == nil, let oldDates = dates {
                    //Add new date to arr
                    if !readDates.contains { $0 == date } {
                        readDates = oldDates
                        readDates.append(date)
                    } else {
                        completion(nil)
                    }
                } else { //Case where no read dates existed
                    readDates = [date]
                }
                //Save read dates
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(readDates) {
                    self.save(data, url) { error in
                        completion(error)
                    }
                } else {
                    throw StoreError.parseError(msg: "Could not encode to json")
                }
            } catch {
                completion(StoreError.parseError(msg: "Could not encode to json"))
            }
        }
    }
    
    
    private func read<T: Codable>(fromPath: String, _ resource: T.Type, completion: @escaping (T?, Error?) -> Void) {
        do {
            let (manager, path, _) = try urlPackage(forPath: "\(fromPath)")
            if let data = manager.contents(atPath: path) {
                parse(data, T.self, completion)
            } else {
               throw StoreError.readError(msg: "No data could be read from file \(fromPath)")
            }
        } catch let error {
            completion(nil, error)
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
    
    private func parse<T: Codable>(_ data: Data, _ resource: T.Type, _ completion: @escaping (T?, Error?) -> Void) {
        let decoder = JSONDecoder()
        do {
            let models = try decoder.decode(T.self, from: data)
            return completion(models, nil)
        } catch {
            completion(nil, StoreError.parseError(msg: "Could not read devotions from documents"))
        }
    }
    
    private func save(_ data: Data, _ pathUrl: URL, _ completion: @escaping (Error?) -> Void) {
        do {
            try data.write(to: pathUrl, options: [.atomic])
            return completion(nil)
        } catch {
            completion(MBDeserializationError.fetchError(msg: "Could not save devotions to documents directory"))
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
