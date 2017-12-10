//
//  ArticlePicture+CoreDataProperties.swift
//  
//
//  Created by Alex Ramey on 12/9/17.
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
