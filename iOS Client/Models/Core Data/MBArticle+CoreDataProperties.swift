//
//  MBArticle+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 3/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


extension MBArticle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MBArticle> {
        return NSFetchRequest<MBArticle>(entityName: "Article")
    }

    @NSManaged public var articleID: Int32
    @NSManaged public var authorID: Int32
    @NSManaged public var content: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var imageID: Int32
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var link: String?
    @NSManaged public var title: String?
    @NSManaged public var imageLink: String?
    @NSManaged public var thumbnailLink: String?
    @NSManaged public var author: MBAuthor?
    @NSManaged public var categories: NSSet?
    @NSManaged public var image: ArticlePicture?

}

// MARK: Generated accessors for categories
extension MBArticle {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: MBCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: MBCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}
