//
//  ArticlePicture+CoreDataProperties.swift
//  iOS Client
//
//  Created by Alex Ramey on 3/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


extension ArticlePicture {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticlePicture> {
        return NSFetchRequest<ArticlePicture>(entityName: "ArticlePicture")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var article: MBArticle?

}
