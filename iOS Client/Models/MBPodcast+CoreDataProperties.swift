//
//  MBPodcast+CoreDataProperties.swift
//  
//
//  Created by Jonathan Witten on 12/9/17.
//
//

import Foundation
import CoreData


extension MBPodcast {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MBPodcast> {
        return NSFetchRequest<MBPodcast>(entityName: "Podcast")
    }

    @NSManaged public var title: String?
    @NSManaged public var summary: String?
    @NSManaged public var image: String?
    @NSManaged public var guid: String?
    @NSManaged public var pubDate: NSDate?
    @NSManaged public var duration: String?
    @NSManaged public var keywords: String?
    @NSManaged public var author: String?

}
