//
//  MBArticlesStore.swift
//  iOS Client
//
//  Created by Alex Ramey on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

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
    func syncAllData(managedObjectContext: NSManagedObjectContext) -> Promise<Bool> {
        return Promise { fulfill, reject in
            var results: [Bool] = []
            let bgq = DispatchQueue.global(qos: .userInitiated)
            firstly {
                downloadAuthors(managedObjectContext: managedObjectContext)
            }.then(on: bgq) { result -> Promise<Bool> in
                results.append(result)
                return self.downloadCategories(managedObjectContext: managedObjectContext)
            }.then(on: bgq) { result -> Promise<Bool> in
                results.append(result)
                if let linkErr = self.linkCategoriesTogether(managedObjectContext: managedObjectContext) {
                    reject(linkErr)
                }
                return self.downloadArticles(managedObjectContext: managedObjectContext)
            }.then(on: bgq) { result -> Void in
                results.append(result)
                
                // fire off requests to get the image urls
                self.resolveArticleImageURLs(managedObjectContext: managedObjectContext)
                
                fulfill(results.reduce(false, { (accumulator, item) -> Bool in
                    return accumulator || item
                }))
            }.catch { error in
                print("There was an error downloading data! \(error)")
                reject(error)
            }
        }
    }
    
    private func resolveArticleImageURLs(managedObjectContext: NSManagedObjectContext) {
        let articles = self.getArticles(managedObjectContext: managedObjectContext)
        managedObjectContext.perform {
            articles.forEach { (article) in
                if (article.imageID > 0) && (article.imageLink == nil) {
                    self.client.getImageURL(imageID: Int(article.imageID), completion: { (link) in
                        managedObjectContext.perform {
                            article.imageLink = link
                            do {
                                try managedObjectContext.save()
                            } catch {
                                print("😅 wat \(error as Any)")
                            }
                        }
                    })
                }
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
    
    private func downloadAuthors(managedObjectContext: NSManagedObjectContext) -> Promise<Bool> {
        return performDownload(clientFunction: client.getAuthorsWithCompletion, managedObjectContext: managedObjectContext, deserializeFunc: MBAuthor.deserialize)
    }
    
    private func downloadCategories(managedObjectContext: NSManagedObjectContext) -> Promise<Bool> {
        return performDownload(clientFunction: client.getCategoriesWithCompletion, managedObjectContext: managedObjectContext, deserializeFunc: MBCategory.deserialize)
    }
    
    private func downloadArticles(managedObjectContext: NSManagedObjectContext) -> Promise<Bool> {
        return performDownload(clientFunction: client.getArticlesWithCompletion, managedObjectContext: managedObjectContext, deserializeFunc: MBArticle.deserialize)
    }
    
    // An internal helper function to perform a download
    private func performDownload(clientFunction: (@escaping ([Data], Error?) -> Void) -> Void,
                                 managedObjectContext: NSManagedObjectContext,
                                 deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool) -> Promise<Bool> {
        return Promise { fulfill, reject in
            clientFunction { (data: [Data], err: Error?) in
                if let clientErr = err {
                    reject(clientErr)
                    return
                }
                
                var isNewData = false
                var caughtError: Error? = nil
                // data is an array of Data, where each datum is a serialized array representing a page of results
                // thus, think of data as an array of results pages
                for jsonData in data {
                    do {
                        isNewData = try self.downloadModelsHandler(managedObjectContext: managedObjectContext,
                                                       data: jsonData,
                                                       deserializeFunc: deserializeFunc) || isNewData
                    } catch {
                        print("could not handle data: \(error) \(error.localizedDescription)")
                        caughtError = error
                    }
                }
                
                if let error = caughtError {
                    reject(error)
                } else {
                    fulfill(isNewData)
                }
            }
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
    
    /***** Data Cleanup Task *****/
    func deleteOldArticles(managedObjectContext: NSManagedObjectContext, completion: @escaping (Int) -> Void) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == %@", NSNumber(value: false))
        
        managedObjectContext.perform {
            guard let count = try? managedObjectContext.count(for: fetchRequest) else {
                completion(0)
                return
            }
            
            let numToDelete = count - MBConstants.MAX_ARTICLES_ON_DEVICE
            guard numToDelete > 0 else {
                completion(0)
                return
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: true)]
            fetchRequest.fetchLimit = numToDelete
            guard let articlesToDelete = try? managedObjectContext.fetch(fetchRequest) else {
                completion(0)
                return
            }
            
            articlesToDelete.forEach({ (article) in
                managedObjectContext.delete(article)
            })
            
            do {
                try managedObjectContext.save()
                completion(articlesToDelete.count)
            } catch let error as NSError {
                print("Could not save context: \(error), \(error.userInfo)")
                completion(0)
            }
        }
    }
    
}
