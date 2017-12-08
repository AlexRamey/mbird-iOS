//
//  MBArticle+Custom.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/6/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import CoreData
import Foundation

extension MBArticle {
    static let entityName: String = "Article"
    
    // deserialize accepts an NSDictionary and deserializes the object into the provided
    // managedObjectContext. It returns an error if something goes wrong.
    // If the article already existed, then it updates its fields from the new json
    // values. If no article with the json's id value already existed, a new one is
    // created and inserted into the managedContext.
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) throws -> Bool {
        var isNewData: Bool = false
        
        guard let idArg = json.object(forKey: "id") as? Int32 else {
            throw(MBDeserializationError.contractMismatch(msg: "unable to cast json 'id' into an Int32"))
        }
        
        let predicate = NSPredicate(format: "articleID == %d", idArg)
        let fetchRequest = NSFetchRequest<MBArticle>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedArticle: MBArticle? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedArticle = fetchedEntities.first
        } catch {
            throw(MBDeserializationError.fetchError(msg: "error while fetching article with id: \(idArg)"))
        }
        
        if resolvedArticle == nil {
            print("new article!")
            isNewData = true
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedArticle = NSManagedObject(entity: entity, insertInto: managedContext) as? MBArticle
        }
        
        guard let article = resolvedArticle else {
            throw(MBDeserializationError.contextInsertionError(msg: "unable to resolve article with id: \(idArg) into managed context"))
        }
        
        article.setValue(json.object(forKey: "id") as? Int32, forKey: "articleID")
        article.setValue(json.value(forKeyPath: "author") as? Int32, forKey: "authorID")
        article.setValue(json.value(forKeyPath: "featured_media") as? Int32, forKey: "imageID")
        article.setValue(json.value(forKeyPath: "title.rendered") as? String, forKey: "title")
        article.setValue(json.value(forKeyPath: "content.rendered") as? String, forKey: "content")
        
        if let dateStr = json.value(forKeyPath: "date") as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let timeZone = TimeZone(identifier: "America/New_York") {
                dateFormatter.timeZone = timeZone
            }
            article.setValue(dateFormatter.date(from: dateStr), forKey: "date")
        }
        
        if let authorID = json.object(forKey: "author") as? Int32 {
            let predicate = NSPredicate(format: "authorID == %d", authorID)
            let fetchRequest = NSFetchRequest<MBAuthor>(entityName: MBAuthor.entityName)
            fetchRequest.predicate = predicate
            
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                article.author = fetchedEntities.first
            } catch {
                throw(MBDeserializationError.fetchError(msg: "error while fetching article author with id: \(authorID)"))
            }
        }
        
        if let categoryIDs = json.object(forKey: "categories") as? [Int32] {
            for categoryID in categoryIDs {
                let predicate = NSPredicate(format: "categoryID == %d", categoryID)
                let fetchRequest = NSFetchRequest<MBCategory>(entityName: MBCategory.entityName)
                fetchRequest.predicate = predicate
                
                do {
                    let fetchedEntities = try managedContext.fetch(fetchRequest)
                    if let cat = fetchedEntities.first {
                        article.addToCategories(cat)
                    }
                } catch {
                    throw(MBDeserializationError.fetchError(msg: "error while fetching article category with id: \(categoryID)"))
                }
            }
        }
        
        return isNewData
    }
    
    func getTopLevelCategories() -> Set<String> {
        guard let cats = self.categories else {
            return []
        }
        
        // use a set to remove duplicates
        return Set(cats.flatMap { return ($0 as? MBCategory)?.getTopLevelCategory()?.name })
    }
}

extension MBArticle: Detailable {
    
}
