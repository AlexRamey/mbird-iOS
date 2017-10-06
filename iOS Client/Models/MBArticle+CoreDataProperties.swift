//
//  MBArticle+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


extension MBArticle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MBArticle> {
        return NSFetchRequest<MBArticle>(entityName: "Article")
    }

    @NSManaged public var content: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var id: Int32
    @NSManaged public var title: String?
    @NSManaged public var author: MBAuthor?
    @NSManaged public var categories: MBCategory?

}
