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
    
    /***** Read from Core Data *****/
    func getAuthors(managedObjectContext: NSManagedObjectContext) -> [MBAuthor] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName)
        return performFetch(managedContext: managedObjectContext, fetchRequest: fetchRequest) as? [MBAuthor] ?? []
    }
    
    func getCategories(managedObjectContext: NSManagedObjectContext) -> [MBCategory] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        return performFetch(managedContext: managedObjectContext, fetchRequest: fetchRequest) as? [MBCategory] ?? []
    }
    
    func getArticles(managedObjectContext: NSManagedObjectContext) -> [MBArticle] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        return performFetch(managedContext: managedObjectContext, fetchRequest: fetchRequest) as? [MBArticle] ?? []
    }
    
    private func performFetch(managedContext: NSManagedObjectContext, fetchRequest: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
        var retVal: [NSManagedObject] = []
        
        managedContext.performAndWait {
            do {
                retVal = try managedContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                retVal = []
            }
        }
        
        return retVal
    }
    
    /***** Download Data from Network *****/
    func syncAllData(managedObjectContext: NSManagedObjectContext, completion: @escaping (Bool?, Error?) -> Void) {
        var isNewData: Bool = false
        downloadAuthors(managedObjectContext: managedObjectContext) { (isNewAuthorData, authorsErr) in
            if let unwrappedAuthorsErr = authorsErr {
                print("There was an error downloading author data! \(unwrappedAuthorsErr)")
                completion(nil, authorsErr)
            } else {
                self.downloadCategories(managedObjectContext: managedObjectContext, completion: { (isNewCategoryData, catErr) in
                    if let unwrappedCatErr = catErr {
                        print("There was an error downloading category data! \(unwrappedCatErr)")
                        completion(nil, catErr)
                    } else {
                        if let linkErr = self.linkCategoriesTogether(managedObjectContext: managedObjectContext) {
                            print("There was an error linking categories! \(linkErr)")
                            completion(nil, linkErr)
                        } else {
                                self.downloadArticles(managedObjectContext: managedObjectContext, completion: { (isNewArticleData, articleErr) in
                                    if let unwrappedArticleErr = articleErr {
                                        print("There was an error downloading article data! \(unwrappedArticleErr)")
                                        completion(nil, articleErr)
                                    } else {
                                        isNewData = isNewAuthorData ?? false || isNewCategoryData ?? false || isNewArticleData ?? false
                                        completion(isNewData, nil)
                                    }
                                })
                            }
                        }
                })
            }
        }
    }
    
    private func linkCategoriesTogether(managedObjectContext: NSManagedObjectContext) -> Error? {
        let fetchRequest: NSFetchRequest<MBCategory> = MBCategory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "parentID", ascending: true)]
        
        var caughtError: Error? = nil
        managedObjectContext.performAndWait {
            do {
                let fetchedCategories = try managedObjectContext.fetch(fetchRequest) as [MBCategory]
                var categoriesByID = [Int32: MBCategory]()
                fetchedCategories.forEach({ (category) in
                    categoriesByID[category.categoryID] = category
                })
                fetchedCategories.forEach({ (category) in
                    category.parent = categoriesByID[category.parentID]
                })
                try managedObjectContext.save()
            } catch {
                print("Could not fetch. \(error) \(error.localizedDescription)")
                caughtError = error
            }
        }
        
        return caughtError
    }
    
    private func downloadAuthors(managedObjectContext: NSManagedObjectContext, completion: @escaping (Bool?, Error?) -> Void) {
        performDownload(clientFunction: client.getAuthorsWithCompletion, managedObjectContext: managedObjectContext, deserializeFunc: MBAuthor.deserialize, completion: completion)
    }
    
    private func downloadCategories(managedObjectContext: NSManagedObjectContext, completion: @escaping (Bool?, Error?) -> Void) {
        performDownload(clientFunction: client.getCategoriesWithCompletion, managedObjectContext: managedObjectContext, deserializeFunc: MBCategory.deserialize, completion: completion)
    }
    
    private func downloadArticles(managedObjectContext: NSManagedObjectContext, completion: @escaping (Bool?, Error?) -> Void) {
        performDownload(clientFunction: client.getArticlesWithCompletion, managedObjectContext: managedObjectContext, deserializeFunc: MBArticle.deserialize, completion: completion)
    }
    
    // An internal helper function to perform a download
    private func performDownload(clientFunction: (@escaping ([Data], Error?) -> Void) -> Void,
                                 managedObjectContext: NSManagedObjectContext,
                                 deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool,
                                 completion: @escaping (Bool?, Error?) -> Void) {
        
        clientFunction { (data: [Data], err: Error?) in
            if let clientErr = err {
                completion(false, clientErr)
                return
            }
            
            var isNewData = false
            // data is an array of Data, where each datum is a serialized array representing a page of results
            // thus, think of data as an array of results pages
            for jsonData in data {
                do {
                    isNewData = try self.downloadModelsHandler(managedObjectContext: managedObjectContext,
                                                   data: jsonData,
                                                   deserializeFunc: deserializeFunc) || isNewData
                } catch {
                    print("could not handle data: \(error) \(error.localizedDescription)")
                    completion(false, error)
                }
            }
            
            completion(isNewData, nil)
        }
    }
    
    // An internal helper that returns a handler which saves the json array as a group of core data objects
    private func downloadModelsHandler(managedObjectContext: NSManagedObjectContext,
                                       data: Data,
                                       deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool) throws -> Bool {
        
        // deserialize data into the managed context and save it
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        if let arr = json as? [NSDictionary] {
            var isNewData: Bool = false
            var caughtError: Error? = nil
            
            managedObjectContext.performAndWait {
                do {
                    try arr.forEach({ (json: NSDictionary) in
                        if try deserializeFunc(json, managedObjectContext) {
                            isNewData = true
                        }
                    })
                    
                    try managedObjectContext.save()
                } catch {
                   caughtError = error
                }
            }
            
            if let error = caughtError {
                throw MBDeserializationError.contextInsertionError(msg: "an unexpected error occurred: \(error) :\(error.localizedDescription)")
            }
            
            return isNewData
        } else {
            throw MBDeserializationError.contractMismatch(msg: "unable to cast json object into an array of NSDictionary objects")
        }
    }
}
