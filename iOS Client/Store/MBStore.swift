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
    
    /***** Read Data from Core Data *****/
    func getAuthors(managedContext: NSManagedObjectContext) -> [MBAuthor] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName)
        return performFetch(managedContext: managedContext, fetchRequest: fetchRequest) as? [MBAuthor] ?? []
    }
    
    func getCategories(managedContext: NSManagedObjectContext) -> [MBCategory] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        return performFetch(managedContext: managedContext, fetchRequest: fetchRequest) as? [MBCategory] ?? []
    }
    
    func getArticles(managedContext: NSManagedObjectContext) -> [MBArticle] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        return performFetch(managedContext: managedContext, fetchRequest: fetchRequest) as? [MBArticle] ?? []
    }
    
    private func performFetch(managedContext: NSManagedObjectContext, fetchRequest: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }
    
    
    /***** Download Data from Network *****/
    func syncAllData(context: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
        var isNewData: Bool = false
        
        downloadAuthors(context: context) { (isNewAuthorData, authorsErr) in
            isNewData = isNewAuthorData
            if authorsErr != nil {
                print("There was an error downloading author data!")
                completion(isNewData, authorsErr)
            } else {
                self.downloadCategories(context: context, completion: { (isNewCategoryData, catErr) in
                    isNewData = isNewAuthorData || isNewCategoryData
                    if catErr != nil {
                        print("There was an error downloading category data!")
                        completion(isNewData, catErr)
                    } else {
                        self.downloadArticles(context: context, completion: { (isNewArticleData, articleErr) in
                            isNewData = isNewAuthorData || isNewCategoryData || isNewArticleData
                            if articleErr != nil {
                                print("There was an error downloading article data!")
                                completion(isNewData, articleErr)
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
    func syncDevotions(completion: @escaping ([MBDevotion]?, Error?) -> Void) {
        loadDevotions { (devotions, devotionError) in
            completion(devotions, devotionError)
        }
    }
    
    private func downloadAuthors(context: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
        performDownload(clientFunction: client.getAuthorsWithCompletion, managedContext: context, deserializeFunc: MBAuthor.deserialize, completion: completion)
    }
    
    private func downloadCategories(context: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
        performDownload(clientFunction: client.getCategoriesWithCompletion, managedContext: context, deserializeFunc: MBCategory.deserialize, completion: completion)
    }
    
    private func downloadArticles(context: NSManagedObjectContext, completion: @escaping (Bool, Error?) -> Void) {
        performDownload(clientFunction: client.getArticlesWithCompletion, managedContext: context, deserializeFunc: MBArticle.deserialize, completion: completion)
    }
    
    private func loadDevotions(completion: @escaping ([MBDevotion]?, Error?) -> Void) {
        
        let manager = FileManager.default
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first as URL? else {
            completion(nil, MBDeserializationError.contextInsertionError(msg: "Could not create Devotions path"))
            return
        }
        let path = url.path.appending("/devotions")
        let pathUrl = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: path) {
            client.getDevotionsWithCompletion { data, error in
                if error == nil, let data = data {
                    self.save(data, pathUrl) { error in
                        if error != nil {
                            print("Could not save devotions data to disk")
                        }
                    }
                    self.parse(data, [MBDevotion].self, completion)
                } else {
                    completion(nil, error)
                }
            }
        } else if let data = FileManager.default.contents(atPath: path) {
            parse(data, [MBDevotion].self, completion)
        } else {
            completion(nil, MBDeserializationError.fetchError(msg: "Could not fetch devotions"))
        }
    }
    
    private func parse<T: Codable>(_ data: Data, _ resource: T.Type, _ completion: @escaping (T?, Error?) -> Void) {
        let decoder = JSONDecoder()
        do {
            let models = try decoder.decode(T.self, from: data)
            return completion(models, nil)
        } catch {
            completion(nil, MBDeserializationError.fetchError(msg: "Could not read devotions from documents"))
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
                                 managedContext: NSManagedObjectContext,
                                 deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool,
                                 completion: @escaping (Bool, Error?) -> Void) {
        
        var isNewData: Bool = false
        clientFunction { (data: [Data], err: Error?) in
            if let clientErr = err {
                completion(false, clientErr)
                return
            }
            
            for jsonData in data {
                do {
                    if try self.downloadModelsHandler(managedContext: managedContext, data: jsonData, deserializeFunc: deserializeFunc) {
                        isNewData = true
                    }
                } catch {
                    completion(isNewData, error)
                }
            }
            
            completion(isNewData, nil)
        }
        
    }
    
    // An internal helper that returns a handler which saves the json array as a group of core data objects
    private func downloadModelsHandler(managedContext: NSManagedObjectContext, data: Data, deserializeFunc: (NSDictionary, NSManagedObjectContext) throws -> Bool) throws -> Bool {
        
        var json : Any
        var isNewData: Bool = false

        // deserialize data into the managed context and save it
        json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        if let arr = json as? [NSDictionary] {
            
            try arr.forEach({ (json: NSDictionary) in
                if try deserializeFunc(json, managedContext) {
                    isNewData = true
                }
            })
            
            try managedContext.save()
        }
        
        return isNewData
    }
}
