//
//  MBArticlesStore.swift
//  iOS Client
//
//  Created by Alex Ramey on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import CoreData

class MBArticlesStore: NSObject {
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
                        self.linkCategoriesTogether(persistentContainer: persistentContainer, completion: { (linkErr) in
                            if let unwrappedLinkErr = linkErr {
                                print("There was an error linking categories! \(unwrappedLinkErr)")
                                completion(nil, linkErr)
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
                })
            }
        }
    }
    
    private func linkCategoriesTogether(persistentContainer: NSPersistentContainer, completion: @escaping (Error?) -> Void) {
        persistentContainer.performBackgroundTask { (managedContext) in
            let fetchRequest: NSFetchRequest<MBCategory> = MBCategory.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "parentID", ascending: true)]
            do {
                let fetchedCategories = try managedContext.fetch(fetchRequest) as [MBCategory]
                var categoriesByID = [Int32: MBCategory]()
                fetchedCategories.forEach({ (category) in
                    categoriesByID[category.categoryID] = category
                })
                fetchedCategories.forEach({ (category) in
                    category.parent = categoriesByID[category.parentID]
                })
                try managedContext.save()
                completion(nil)
            } catch {
                print("Could not fetch. \(error)")
                completion(error)
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
