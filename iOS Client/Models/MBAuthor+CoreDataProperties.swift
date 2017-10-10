//
//  MBAuthor+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
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

}
