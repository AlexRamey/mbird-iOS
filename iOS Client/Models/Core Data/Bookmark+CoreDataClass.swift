//
//  Bookmark+CoreDataClass.swift
//  iOS Client
//
//  Created by Alex Ramey on 8/27/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Bookmark)
public class Bookmark: NSManagedObject {
    static let entityName: String = "Bookmark"
    
    class func newBookmark(fromArticle from: Article, inContext managedContext: NSManagedObjectContext) -> Bookmark? {
        let (bookmark, _) = self.resolveOrCreateBookmarkById(from.articleId, inContext: managedContext)
        guard let resolvedBookmark = bookmark else {
            return nil
        }
        
        resolvedBookmark.articleId = Int32(from.articleId)
        resolvedBookmark.link = from.link
        resolvedBookmark.title = from.title
        resolvedBookmark.content = from.content
        resolvedBookmark.imageId = Int32(from.imageId)
        resolvedBookmark.thumbnailLink = from.image?.thumbnailUrl?.absoluteString
        resolvedBookmark.date = from.getDate() as NSDate?
        resolvedBookmark.category = from.categories.first?.name
        resolvedBookmark.author = from.author?.name
        return resolvedBookmark
    }
    
    private class func resolveOrCreateBookmarkById(_ articleId: Int, inContext context: NSManagedObjectContext) -> (Bookmark?, Bool) {
        
        let predicate = NSPredicate(format: "articleId == %d", articleId)
        let fetchRequest = NSFetchRequest<Bookmark>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedEntities = try context.fetch(fetchRequest)
            if let bookmark = fetchedEntities.first {
                return (bookmark, false)
            }
        } catch {
            print("error fetching bookmark by id")
            return (nil, false)
        }
        
        let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: context)!
        
        guard let resolvedBookmark = NSManagedObject(entity: entity, insertInto: context) as? Bookmark else {
            return (nil, false)
        }
        
        return (resolvedBookmark, true)
    }
    
    func toDomain() -> Article {
        var strDate: String?
        if let date = self.date as Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            strDate = dateFormatter.string(from: date)
        }
        
        let cats: [Category] = [Category(categoryId: -1, name: self.category ?? "unclassified", parentId: 0)]
        
        var image: Image?
        if self.imageId != 0, let imageLink = self.thumbnailLink {
            image = Image(imageId: Int(self.imageId), thumbnailUrl: URL(string: imageLink))
        }
        
        return Article(articleId: Int(self.articleId), date: strDate ?? "", link: self.link ?? "", title: self.title ?? "", authorId: -1, author: Author(authorId: -1, name: self.author ?? "", info: ""), imageId: Int(self.imageId), image: image, content: self.content ?? "", categoryIds: [], categories: cats, isBookmarked: true)
    }
}
