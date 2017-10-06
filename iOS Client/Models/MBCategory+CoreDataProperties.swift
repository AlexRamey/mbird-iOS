//
//  MBCategory+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


extension MBCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MBCategory> {
        return NSFetchRequest<MBCategory>(entityName: "Category")
    }

    @NSManaged public var id: Int32
    @NSManaged public var name: String?
    @NSManaged public var parent: Int32

}
