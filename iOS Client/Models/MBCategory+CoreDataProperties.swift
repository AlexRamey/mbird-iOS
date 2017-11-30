//
//  MBCategory+CoreDataProperties.swift
//
//
//  Created by Alex Ramey on 11/14/17.
//
//

import Foundation
import CoreData


extension MBCategory {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MBCategory> {
        return NSFetchRequest<MBCategory>(entityName: "Category")
    }
    
    @NSManaged public var categoryID: Int32
    @NSManaged public var name: String?
    @NSManaged public var parentID: Int32
    @NSManaged public var articles: NSSet?
    @NSManaged public var parent: MBCategory?
    
}

// MARK: Generated accessors for articles
extension MBCategory {
    
    @objc(addArticlesObject:)
    @NSManaged public func addToArticles(_ value: MBArticle)
    
    @objc(removeArticlesObject:)
    @NSManaged public func removeFromArticles(_ value: MBArticle)
    
    @objc(addArticles:)
    @NSManaged public func addToArticles(_ values: NSSet)
    
    @objc(removeArticles:)
    @NSManaged public func removeFromArticles(_ values: NSSet)
    
}
