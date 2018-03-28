//
//  MBCategory+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 3/25/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
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
    @NSManaged public var children: NSSet?
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

// MARK: Generated accessors for children
extension MBCategory {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: MBCategory)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: MBCategory)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}
