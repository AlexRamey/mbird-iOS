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
    
    class func newArticle(fromArticle from: Article, inContext managedContext: NSManagedObjectContext) -> MBArticle? {
        let (article, _) = self.resolveOrCreateArticleById(from.articleId, inContext: managedContext)
        guard let resolvedArticle = article else {
            return nil
        }
        
        resolvedArticle.articleID = Int32(from.articleId)
        resolvedArticle.isBookmarked = from.isBookmarked
        resolvedArticle.link = from.link
        resolvedArticle.title = from.title
        resolvedArticle.content = from.content
        resolvedArticle.imageID = Int32(from.imageId)
        resolvedArticle.thumbnailLink = from.image?.thumbnailUrl?.absoluteString
        resolvedArticle.authorOverride = from.authorOverride
        
        linkArticle(resolvedArticle, toAuthor: from.authorId)
        linkArticle(resolvedArticle, toCategories: from.categoryIds)

        resolvedArticle.date = from.getDate() as NSDate?
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
        let predicate = NSPredicate(format: "categoryID in %@", catIds)
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


        let categories = self.getTopLevelCategories()
        let catIds: [Int] = categories.map { return Int($0.categoryID) }
        let cats: [Category] = categories.map { return $0.toDomain() }
        
        var image: Image?
        if self.imageID != 0, let imageLink = self.thumbnailLink {
            image = Image(imageId: Int(self.imageID), thumbnailUrl: URL(string: imageLink))
        }
        
        return Article(articleId: Int(self.articleID), date: strDate ?? "", link: self.link ?? "", title: self.title ?? "", authorId: Int(self.authorID), author: self.author?.toDomain(), imageId: Int(self.imageID), image: image, content: self.content ?? "", categoryIds: catIds, categories: cats, isBookmarked: self.isBookmarked, authorOverride: self.authorOverride)
    }
    
    private func getTopLevelCategories() -> [MBCategory] {
        guard let cats = self.categories else {
            return []
        }
        
        // use a set to remove duplicates
        return Array(Set(cats.compactMap { return ($0 as? MBCategory)?.getTopLevelCategory() }))
    }
}
