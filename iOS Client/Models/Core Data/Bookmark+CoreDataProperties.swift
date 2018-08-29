//
//  Bookmark+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 8/27/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


extension Bookmark {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bookmark> {
        return NSFetchRequest<Bookmark>(entityName: "Bookmark")
    }

    @NSManaged public var articleId: Int32
    @NSManaged public var author: String?
    @NSManaged public var content: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var imageLink: String?
    @NSManaged public var link: String?
    @NSManaged public var title: String?
    @NSManaged public var category: String?
    @NSManaged public var imageId: Int32

}
