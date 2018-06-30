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

class MBArticlesStore: NSObject, AuthorDAO, CategoryDAO {
    private let client: MBClient
    private let managedObjectContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        client = MBClient()
        self.managedObjectContext = context
        
        super.init()
    }
    
    /***** Author DAO *****/
    func getAuthorById(_ id: Int) -> Author? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName)
        fetchRequest.predicate = NSPredicate(format: "authorID == %d", id)
        if let results = performFetch(fetchRequest: fetchRequest) as? [MBAuthor] {
            return results.first?.toDomain()
        }
        return nil
    }
    
    /***** Category DAO *****/
    func getCategoriesById(_ ids: [Int]) -> [Category] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        fetchRequest.predicate = NSPredicate(format: "ANY categoryID in %@", ids)
        if let results = performFetch(fetchRequest: fetchRequest) as? [MBCategory] {
            return results.map { $0.toDomain() }
        }
        return []
    }
    
    /***** Read from Core Data *****/
    func getAuthors() -> [MBAuthor] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName)
        return performFetch(fetchRequest: fetchRequest) as? [MBAuthor] ?? []
    }
    
    func getCategories() -> [MBCategory] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        return performFetch(fetchRequest: fetchRequest) as? [MBCategory] ?? []
    }
    
    func getCategoryByName(_ name: String) -> MBCategory? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        guard let results = performFetch(fetchRequest: fetchRequest) as? [MBCategory] else {
            return nil
        }
        return results.first
    }
    
    func getArticles() -> [MBArticle] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        let sort = NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        return performFetch(fetchRequest: fetchRequest) as? [MBArticle] ?? []
    }
    
    func getCategoryArticles(categoryIDs: [Int], skip: Int) -> [MBArticle] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        let sort = NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.fetchOffset = skip
        fetchRequest.predicate = NSPredicate(format: "ANY categories.categoryID in %@", categoryIDs)
        return performFetch(fetchRequest: fetchRequest) as? [MBArticle] ?? []
    }
    
    private func performFetch(fetchRequest: NSFetchRequest<NSManagedObject>) -> [NSManagedObject] {
        var retVal: [NSManagedObject] = []
        
        self.managedObjectContext.performAndWait {
            do {
                retVal = try managedObjectContext.fetch(fetchRequest)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
                retVal = []
            }
        }
        
        return retVal
    }
    
    /***** Download Data from Network *****/
    func syncAllData() -> Promise<Bool> {
        return Promise { fulfill, reject in
            var results: [Bool] = []
            let bgq = DispatchQueue.global(qos: .userInitiated)
            firstly {
                downloadAuthors()
            }.then(on: bgq) { result -> Promise<Bool> in
                results.append(result)
                return self.downloadCategories()
            }.then(on: bgq) { result -> Promise<Bool> in
                results.append(result)
                if let linkErr = self.linkCategoriesTogether() {
                    reject(linkErr)
                }
                return self.downloadArticles()
            }.then(on: bgq) { result -> Void in
                results.append(result)
                
                // fire off requests to get the image urls
                self.resolveArticleImageURLs()
                
                fulfill(results.reduce(false, { (accumulator, item) -> Bool in
                    return accumulator || item
                }))
            }.catch { error in
                print("There was an error downloading data! \(error)")
                reject(error)
            }
        }
    }
    
    func downloadImageURLsForArticle(_ article: MBArticle, withCompletion completion: @escaping (URL?) -> Void) {
        self.client.getImageURLs(imageID: Int(article.imageID)) { links in
            if let context = article.managedObjectContext {
                context.perform {
                    do {
                        article.thumbnailLink = links?[0]
                        article.imageLink = links?[1]
                        try context.save()
                        if let imageLink = article.thumbnailLink ?? article.imageLink,
                            let url = URL(string: imageLink) {
                             completion(url)
                        } else {
                            completion(nil)
                        }
                    } catch {
                        print("😅 unable to save image url for \(article.articleID)")
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func resolveArticleImageURLs() {
        let articles = self.getArticles()
        self.managedObjectContext.perform {
            articles.forEach { (article) in
                if (article.imageID > 0) && (article.imageLink == nil) {
                    self.client.getImageURLs(imageID: Int(article.imageID), completion: { (links) in
                        self.managedObjectContext.perform {
                            article.thumbnailLink = links?[0]
                            article.imageLink = links?[1]
                            do {
                                try self.managedObjectContext.save()
                            } catch {
                                print("😅 wat \(error as Any)")
                            }
                        }
                    })
                }
            }
        }
    }
    
    private func linkCategoriesTogether() -> Error? {
        let fetchRequest: NSFetchRequest<MBCategory> = MBCategory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "parentID", ascending: true)]
        
        var caughtError: Error? = nil
        self.managedObjectContext.performAndWait {
            do {
                let fetchedCategories = try self.managedObjectContext.fetch(fetchRequest) as [MBCategory]
                var categoriesByID = [Int32: MBCategory]()
                fetchedCategories.forEach({ (category) in
                    categoriesByID[category.categoryID] = category
                })
                fetchedCategories.forEach({ (category) in
                    category.parent = categoriesByID[category.parentID]
                })
                try self.managedObjectContext.save()
            } catch {
                print("Could not fetch. \(error) \(error.localizedDescription)")
                caughtError = error
            }
        }
        
        return caughtError
    }
    
    private func downloadAuthors() -> Promise<Bool> {
        return performDownload(clientFunction: client.getAuthorsWithCompletion, deserializeFunc: MBAuthor.deserialize)
    }
    
    private func downloadCategories() -> Promise<Bool> {
        return performDownload(clientFunction: client.getCategoriesWithCompletion, deserializeFunc: MBCategory.deserialize)
    }
    
    private func downloadArticles() -> Promise<Bool> {
        return performDownload(clientFunction: client.getRecentArticlesWithCompletion, deserializeFunc: MBArticle.deserialize)
    }
    
    public func syncCategoryArticles(categories: [Int], excluded: [Int]) -> Promise<Bool> {
        return Promise { fulfill, reject in
            firstly {
                performDownload(clientFunction: { (completion: @escaping ([Data], Error?) -> Void) in
                    client.getRecentArticles(inCategories: categories, excludingArticlesWithIDs: excluded, withCompletion: completion)
                }, deserializeFunc: MBArticle.deserialize)
            }.then() { result -> Void in
                    // fire off requests to get the image urls
                    self.resolveArticleImageURLs()
                    fulfill(result)
            }.catch { error in
                    print("There was an error downloading data! \(error)")
                    reject(error)
            }
        }
    }
    
    // An internal helper function to perform a download
    private func performDownload(clientFunction: (@escaping ([Data], Error?) -> Void) -> Void,
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
                        isNewData = try self.downloadModelsHandler(data: jsonData, deserializeFunc: deserializeFunc) || isNewData
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
    private func downloadModelsHandler(data: Data,
                                       deserializeFunc: @escaping (NSDictionary, NSManagedObjectContext) throws -> Bool) throws -> Bool {
        
        // deserialize data into the managed context and save it
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        if let arr = json as? [NSDictionary] {
            var isNewData: Bool = false
            var caughtError: Error? = nil
            
            self.managedObjectContext.performAndWait {
                do {
                    try arr.forEach({ (json: NSDictionary) in
                        if try deserializeFunc(json, self.managedObjectContext) {
                            isNewData = true
                        }
                    })
                    
                    try self.managedObjectContext.save()
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
    func deleteOldArticles(completion: @escaping (Int) -> Void) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == %@", NSNumber(value: false))
        
        self.managedObjectContext.perform {
            guard let count = try? self.managedObjectContext.count(for: fetchRequest) else {
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
            guard let articlesToDelete = try? self.managedObjectContext.fetch(fetchRequest) else {
                completion(0)
                return
            }
            
            articlesToDelete.forEach({ (article) in
                self.managedObjectContext.delete(article)
            })
            
            do {
                try self.managedObjectContext.save()
                completion(articlesToDelete.count)
            } catch let error as NSError {
                print("Could not save context: \(error), \(error.userInfo)")
                completion(0)
            }
        }
    }
    
}
