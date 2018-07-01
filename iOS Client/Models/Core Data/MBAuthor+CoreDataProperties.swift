//
//  MBAuthor+CoreDataProperties.swift
//
//
//  Created by Alex Ramey on 11/4/17.
//
//

import Foundation
import CoreData


extension MBAuthor {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MBAuthor> {
        return NSFetchRequest<MBAuthor>(entityName: "Author")
    }
    
    @NSManaged public var authorID: Int32
    @NSManaged public var info: String?
    @NSManaged public var name: String?
    @NSManaged public var articles: NSSet?
    
}

// MARK: Generated accessors for articles
extension MBAuthor {
    
    @objc(addArticlesObject:)
    @NSManaged public func addToArticles(_ value: MBArticle)
    
    @objc(removeArticlesObject:)
    @NSManaged public func removeFromArticles(_ value: MBArticle)
    
    @objc(addArticles:)
    @NSManaged public func addToArticles(_ values: NSSet)
    
    @objc(removeArticles:)
    @NSManaged public func removeFromArticles(_ values: NSSet)
    
}
