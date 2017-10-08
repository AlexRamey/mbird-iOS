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
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) -> Error? {
        
        guard let idArg = json.object(forKey: "id") as? Int32 else {
            print("unable to cast json 'id' into an Int32")
            return NSError()
        }
        
        let predicate = NSPredicate(format: "articleID == %d", idArg)
        let fetchRequest = NSFetchRequest<MBArticle>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedArticle: MBArticle? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedArticle = fetchedEntities.first
        } catch let error as NSError {
            print("An error: '\(error)' occurred during the fetch request for a single article")
            return error
        }
        
        if resolvedArticle == nil {
            print("new article!")
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedArticle = NSManagedObject(entity: entity, insertInto: managedContext) as? MBArticle
        }
        
        guard let article = resolvedArticle else {
            print("ERROR: Unable to resolve article!")
            return NSError()
        }
        
        article.setValue(json.object(forKey: "id") as? Int32, forKey: "articleID")
        article.setValue(json.value(forKeyPath: "author") as? Int32, forKey: "authorID")
        article.setValue(json.value(forKeyPath: "title.rendered") as? String, forKey: "title")
        article.setValue(json.value(forKeyPath: "content.rendered") as? String, forKey: "content")
        
        // TODO -- Parse Date --
        // json.value(forKeyPath: "date") as? String
        // date = parsed string
        // article.setValue(date, forKey: "date")
        
        if let authorID = json.object(forKey: "author") as? Int32 {
            let predicate = NSPredicate(format: "authorID == %d", authorID)
            let fetchRequest = NSFetchRequest<MBAuthor>(entityName: MBAuthor.entityName)
            fetchRequest.predicate = predicate
            
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                article.author = fetchedEntities.first
            } catch let error as NSError {
                print("An error: '\(error)' occurred while linking an author to an article")
            }
        }
        
        // TODO -- Link Categories --
        // . . .
        
        return nil
    }
    
}
