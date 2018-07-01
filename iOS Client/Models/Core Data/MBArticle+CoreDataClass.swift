//
//  MBArticle+CoreDataClass.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
//

import UIKit
import CoreData

public class MBArticle: NSManagedObject {
    static let entityName: String = "Article"
    var uiimage: UIImage? = nil
    
    // deserialize accepts an NSDictionary and deserializes the object into the provided
    // managedObjectContext. It returns an error if something goes wrong.
    // If the article already existed, then it updates its fields from the new json
    // values. If no article with the json's id value already existed, a new one is
    // created and inserted into the managedContext.
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) throws -> Bool {
        guard let idArg = json.object(forKey: "id") as? Int else {
            throw(MBDeserializationError.contractMismatch(msg: "unable to cast json 'id' into an Int32"))
        }
        
        var (resolvedArticle, isNewData) = self.resolveOrCreateArticleById(idArg, inContext: managedContext)
        
        guard let article = resolvedArticle else {
            throw(MBDeserializationError.contextInsertionError(msg: "unable to resolve article with id: \(idArg) into managed context"))
        }
        
        article.setValue(json.object(forKey: "id") as? Int32, forKey: "articleID")
        article.setValue(json.value(forKeyPath: "author") as? Int32, forKey: "authorID")
        article.setValue(json.value(forKeyPath: "link") as? String, forKey: "link")
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
        
        if let authorID = json.object(forKey: "author") as? Int {
            linkArticle(article, toAuthor: authorID)
        }
        
        if let categoryIDs = json.object(forKey: "categories") as? [Int] {
            linkArticle(article, toCategories: categoryIDs)
        }
        
        return isNewData
    }
    
    class func newArticle(fromArticle from: Article, inContext managedContext: NSManagedObjectContext) -> MBArticle? {
        let (article, _) = self.resolveOrCreateArticleById(from.id, inContext: managedContext)
        guard let resolvedArticle = article else {
            return nil
        }
        
        resolvedArticle.articleID = Int32(from.id)
        resolvedArticle.isBookmarked = from.isBookmarked
        resolvedArticle.link = from.link
        resolvedArticle.title = from.title
        resolvedArticle.content = from.content
        resolvedArticle.imageID = Int32(from.imageId)
        resolvedArticle.imageLink = from.image?.thumbnailUrl?.absoluteString ?? from.image?.imageUrl?.absoluteString
        
        linkArticle(resolvedArticle, toAuthor: from.authorId)
        linkArticle(resolvedArticle, toCategories: from.categoryIds)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let timeZone = TimeZone(identifier: "GMT") {
            dateFormatter.timeZone = timeZone
        }
        resolvedArticle.date = dateFormatter.date(from: from.date) as NSDate?
        return resolvedArticle
    }
    
    private class func resolveOrCreateArticleById(_ articleId: Int, inContext context: NSManagedObjectContext) -> (MBArticle?, Bool) {
        
        let predicate = NSPredicate(format: "articleID == %d", articleId)
        let fetchRequest = NSFetchRequest<MBArticle>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedEntities = try context.fetch(fetchRequest)
            if let article = fetchedEntities.first {
                return (article, false)
            }
        } catch {
            print("error fetching article by id")
            return (nil, false)
        }
        
        let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: context)!
        
        guard let resolvedArticle = NSManagedObject(entity: entity, insertInto: context) as? MBArticle else {
            return (nil, false)
        }
        
        return (resolvedArticle, true)
    }
    
    private class func linkArticle(_ article: MBArticle, toAuthor authorId: Int) {
        guard let managedContext = article.managedObjectContext else {
                return
        }
        article.authorID = Int32(authorId)
        let predicate = NSPredicate(format: "authorID == %d", authorId)
        let fetchRequest = NSFetchRequest<MBAuthor>(entityName: MBAuthor.entityName)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            article.author = fetchedEntities.first
        } catch {
            print("error resolving author for new article")
        }
    }
    
    private class func linkArticle(_ article: MBArticle, toCategories catIds: [Int]) {
        guard catIds.count > 0,
              let managedContext = article.managedObjectContext else {
                return
        }
        let predicate = NSPredicate(format: "ANY categoryID in %@", catIds)
        let fetchRequest = NSFetchRequest<MBCategory>(entityName: MBCategory.entityName)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            article.addToCategories(NSSet(array: fetchedEntities))
        } catch {
            print("error resolving categories for new article")
        }
    }
    
    func toDomain() -> Article {
        var strDate: String?
        if let date = self.date as Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            strDate = dateFormatter.string(from: date)
        }

        var catIds: [Int] = []
        var cats: [Category] = []
        if let categories = self.categories {
            categories.forEach { (item) in
                if let cat = item as? MBCategory {
                    catIds.append(Int(cat.categoryID))
                    cats.append(cat.toDomain())
                }
            }
        }
        
        var image: Image?
        if self.imageID != 0, let imageLink = self.imageLink {
            image = Image(id: Int(self.imageID), thumbnailUrl: URL(string: imageLink), imageUrl: nil)
        }
        
        return Article(id: Int(self.articleID), date: strDate ?? "", link: self.link ?? "", title: self.title ?? "", authorId: Int(self.authorID), author: self.author?.toDomain(), imageId: Int(self.imageID), image: image, content: self.content ?? "", categoryIds: catIds, categories: cats, isBookmarked: self.isBookmarked)
    }
    
    func getTopLevelCategories() -> Set<String> {
        guard let cats = self.categories else {
            return []
        }
        
        // use a set to remove duplicates
        return Set(cats.flatMap { return ($0 as? MBCategory)?.getTopLevelCategory()?.name })
    }
}
