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
    func syncAllData(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        downloadAuthors(context: context) { (authorsErr) in
            if authorsErr != nil {
                print("There was an error downloading author data!")
                completion(authorsErr)
            } else {
                self.downloadCategories(context: context, completion: { (catErr) in
                    if catErr != nil {
                        print("There was an error downloading category data!")
                        completion(catErr)
                    } else {
                        self.downloadArticles(context: context, completion: { (articleErr) in
                            if articleErr != nil {
                                print("There was an error downloading article data!")
                                completion(articleErr)
                            } else {
                                completion(nil)
                            }
                        })
                    }
                })
            }
        }
    }
    
    private func downloadAuthors(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        performDownload(clientFunction: client.getAuthorsWithCompletion, managedContext: context, deserializeFunc: MBAuthor.deserialize, completion: completion)
    }
    
    private func downloadCategories(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        performDownload(clientFunction: client.getCategoriesWithCompletion, managedContext: context, deserializeFunc: MBCategory.deserialize, completion: completion)
    }
    
    private func downloadArticles(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        performDownload(clientFunction: client.getArticlesWithCompletion, managedContext: context, deserializeFunc: MBArticle.deserialize, completion: completion)
    }
    
    // An internal helper function to perform a download
    private func performDownload(clientFunction: (@escaping (Data?, URLResponse?, Error?) -> Void) -> (),
                                 managedContext: NSManagedObjectContext,
                                 deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) -> Error?,
                                 completion: @escaping (Error?) -> Void) {
        
        clientFunction { (data: Data?, _: URLResponse?, err: Error?) in
            if let jsonData = data {
                self.downloadModelsHandler(managedContext: managedContext, data: jsonData, deserializeFunc: deserializeFunc)
            }
            
            completion(err)
        }
        
    }
    
    // An internal helper that returns a handler which saves the json array as a group of core data objects
    private func downloadModelsHandler(managedContext: NSManagedObjectContext, data: Data, deserializeFunc: (NSDictionary, NSManagedObjectContext) -> Error? ) {
        var json : Any
        do {
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let arr = json as? [NSDictionary] {
                _ = arr.map({(json: NSDictionary) -> Error? in
                    return deserializeFunc(json, managedContext)
                })
                try managedContext.save()
            }
        } catch {
            print(error)
        }
    }
}
