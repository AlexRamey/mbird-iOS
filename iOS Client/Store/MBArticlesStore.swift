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

class MBArticlesStore: NSObject, ArticleDAO, AuthorDAO, CategoryDAO {
    private let client: MBClient
    private let managedObjectContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        client = MBClient()
        self.managedObjectContext = context
        
        super.init()
    }
    
    /***** Author DAO *****/
    func getAuthorById(_ authorId: Int) -> Author? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName)
        fetchRequest.predicate = NSPredicate(format: "authorID == %d", authorId)
        if let results = performFetch(fetchRequest: fetchRequest) as? [MBAuthor] {
            return results.first?.toDomain()
        }
        return nil
    }
    
    /***** Category DAO *****/
    func getAllTopLevelCategories() -> [Category] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        let sort = NSSortDescriptor(key: #keyPath(MBCategory.name), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.predicate = NSPredicate(format: "parentID == %d", 0)
        
        if let categories = performFetch(fetchRequest: fetchRequest) as? [MBCategory] {
            // filter out categories without at least one article
            return categories.filter { (category) -> Bool in
                let lineage = [Int(category.categoryID)] + category.getAllDescendants().map { return Int($0.categoryID) }
                return getLatestCategoryArticles(categoryIDs: lineage, skip: 0).count > 0
            }.map { return $0.toDomain() }
        } else {
            return []
        }
    }
    
    func getCategoriesById(_ ids: [Int]) -> [Category] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        fetchRequest.predicate = NSPredicate(format: "categoryID in %@", ids)
        if let results = performFetch(fetchRequest: fetchRequest) as? [MBCategory] {
            return results.map { $0.toDomain() }
        }
        return []
    }
    
    func getCategoryByName(_ name: String) -> Category? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        guard let results = performFetch(fetchRequest: fetchRequest) as? [MBCategory] else {
            return nil
        }
        return results.first?.toDomain()
    }
    
    func getDescendentsOfCategory(cat: Category) -> [Category] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName)
        fetchRequest.predicate = NSPredicate(format: "categoryID == %d", cat.categoryId)
        if let results = performFetch(fetchRequest: fetchRequest) as? [MBCategory] {
            return results.first?.getAllDescendants().map { return $0.toDomain() } ?? []
        }
        return []
    }
    
    /***** Article DAO *****/
    func downloadImageURLsForArticle(_ article: Article, withCompletion completion: @escaping (URL?) -> Void) {
        guard let entity = MBArticle.newArticle(fromArticle: article, inContext: self.managedObjectContext) else {
            completion(nil)
            return
        }
        
        self.client.getImageById(Int(entity.imageID)) { image in
            self.managedObjectContext.perform {
                do {
                    entity.thumbnailLink = image?.thumbnailUrl?.absoluteString
                    try self.managedObjectContext.save()
                    if let imageLink = entity.thumbnailLink,
                        let url = URL(string: imageLink) {
                        completion(url)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("😅 unable to save image url for \(entity.articleID)")
                    completion(nil)
                }
            }
        }
    }
    
    func getLatestArticles(skip: Int) -> [Article] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        let sort = NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.fetchOffset = skip
        if let articles = performFetch(fetchRequest: fetchRequest) as? [MBArticle] {
            return articles.map { return $0.toDomain() }
        } else {
            return []
        }
    }
    
    func getLatestCategoryArticles(categoryIDs: [Int], skip: Int) -> [Article] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        let sort = NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        fetchRequest.fetchOffset = skip
        fetchRequest.predicate = NSPredicate(format: "ANY categories.categoryID in %@", categoryIDs)
        return (performFetch(fetchRequest: fetchRequest) as? [MBArticle])?.map { $0.toDomain() } ?? []
    }
    
    func bookmarkArticle(_ article: Article) -> Error? {
        guard Bookmark.newBookmark(fromArticle: article, inContext: self.managedObjectContext) != nil else {
            return NSError(domain: "CD Adapter", code: 0, userInfo: nil)
        }
        
        var err: Error?
        self.managedObjectContext.performAndWait {
            do {
                try self.managedObjectContext.save()
            } catch {
                err = error
            }
        }
        return err
    }
    
    func nukeAndPave() -> Promise<[Article]> {
        return Promise { seal in
            firstly {
                when(fulfilled: client.getAuthors(), client.getCategories(), client.getRecentArticles(inCategories: [], offset: 0, pageSize: 100, before: nil, after: nil, asc: false))
            }.done { authors, categories, articles -> Void in
                // build map of image id to image link
                let imageLinkCache = self.getLinks()
                
                // flush db
                if let nukeErr = self.nuke() {
                    throw nukeErr
                }
                
                var saveError: Error?
                // save data
                self.managedObjectContext.performAndWait {
                    do {
                        authors.forEach { MBAuthor.newAuthor(fromAuthor: $0, inContext: self.managedObjectContext ) }
                        try self.managedObjectContext.save()
                        
                        categories.forEach {MBCategory.newCategory(fromCategory: $0, inContext: self.managedObjectContext)}
                        try self.managedObjectContext.save()
                        
                        if let linkErr = self.linkCategoriesTogether() {
                            throw linkErr
                        }
                        
                        articles.forEach {MBArticle.newArticle(fromArticle: $0, inContext: self.managedObjectContext)}
                        try self.managedObjectContext.save()
                    } catch {
                        saveError = error
                    }
                }
                
                if let saveError = saveError {
                    throw saveError
                }

                self.resolveArticleImageURLs(cache: imageLinkCache)
                seal.fulfill(self.getLatestArticles(skip: 0))
            }.catch { error in
                print("There was an error downloading data! \(error)")
                seal.reject(error)
            }
        }
    }
    
    private func nuke() -> Error? {
        let articles = self.performFetch(fetchRequest: NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName))
        
        let authors = self.performFetch(fetchRequest: NSFetchRequest<NSManagedObject>(entityName: MBAuthor.entityName))
        
        let categories = self.performFetch(fetchRequest: NSFetchRequest<NSManagedObject>(entityName: MBCategory.entityName))
        
        let objects = articles + authors + categories
        var retVal: Error?
        self.managedObjectContext.performAndWait {
            for object in objects {
                self.managedObjectContext.delete(object)
            }
            
            do {
                try self.managedObjectContext.save()
            } catch {
                retVal = error
            }
        }
        
        return retVal
    }
    
    private func getLinks() -> [Int: String] {
        let request = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        request.predicate = NSPredicate(format: "thumbnailLink != NULL AND thumbnailLink != %@", "")
        let articles = self.performFetch(fetchRequest: request) as? [MBArticle] ?? []
        
        var retVal: [Int: String] = [:]
        articles.forEach { (article) in
            if let link = article.thumbnailLink {
                retVal[Int(article.imageID)] = link
            } else {
                print("fail")
            }
        }
        return retVal
    }
    
    func saveArticles(articles: [Article]) -> Error? {
        var saveErr: Error?
        self.managedObjectContext.performAndWait {
            articles.forEach { _ = MBArticle.newArticle(fromArticle: $0, inContext: self.managedObjectContext) }
            do {
                try self.managedObjectContext.save()
            } catch {
                print("unable to save articles: \(error)")
                saveErr = error
            }
        }
        return saveErr
    }
    
    /***** Read from Core Data *****/
    func getArticleEntities() -> [MBArticle] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: MBArticle.entityName)
        let sort = NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
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
    
    private func resolveArticleImageURLs(cache: [Int: String]) {
        let articles = self.getArticleEntities()
        
        // resolve image links from cache to prevent unnecessary network calls
        // for image resources
        self.managedObjectContext.performAndWait {
            articles.forEach { (article) in
                if let link = cache[Int(article.imageID)] {
                    article.thumbnailLink = link
                }
            }
            do {
                try self.managedObjectContext.save()
            } catch {
                print("😅 wat \(error as Any)")
            }
        }
        
        // for the other articles whose image id couldn't be resolved to a link
        // from the cache, go ahead and pull down the link
        self.managedObjectContext.perform {
            articles.forEach { (article) in
                if (article.imageID > 0) && (article.thumbnailLink == nil) {
                    self.client.getImageById(Int(article.imageID), completion: { (image) in
                        self.managedObjectContext.perform {
                            article.thumbnailLink = image?.thumbnailUrl?.absoluteString
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
}
