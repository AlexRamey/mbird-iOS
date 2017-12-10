//
//  MBPodcast+Custom.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import CoreData
import Foundation

extension MBPodcast {
    static let entityName: String = "Podcast"
    
    // deserialize accepts an NSDictionary and deserializes the object into the provided
    // managedObjectContext. It returns an error if something goes wrong.
    // If the article already existed, then it updates its fields from the new json
    // values. If no article with the json's id value already existed, a new one is
    // created and inserted into the managedContext.
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) throws -> Bool {
        var isNewData: Bool = false
        
        guard let urlArg = json.object(forKey: "guid") as? String else {
            throw(MBDeserializationError.contractMismatch(msg: "unable to cast json 'id' into an Int32"))
        }
        
        let predicate = NSPredicate(format: "guid == %d", urlArg)
        let fetchRequest = NSFetchRequest<MBPodcast>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedPodcast: MBPodcast? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedPodcast = fetchedEntities.first
        } catch {
            throw(MBDeserializationError.fetchError(msg: "error while fetching article with id: \(urlArg)"))
        }
        
        if resolvedPodcast == nil {
            print("new podcast!")
            isNewData = true
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedPodcast = NSManagedObject(entity: entity, insertInto: managedContext) as? MBPodcast
        }
        
        guard let podcast = resolvedPodcast else {
            throw(MBDeserializationError.contextInsertionError(msg: "unable to resolve article with id: \(urlArg) into managed context"))
        }
        
        podcast.setValue(json.object(forKey: "guid") as? String, forKey: "guid")
        podcast.setValue(json.value(forKeyPath: "author") as? String, forKey: "author")
        podcast.setValue(json.value(forKeyPath: "duration") as? String, forKey: "duration")
        podcast.setValue(json.value(forKeyPath: "image") as? String, forKey: "image")
        podcast.setValue(json.value(forKeyPath: "keywords") as? String, forKey: "keywords")
        podcast.setValue(json.value(forKeyPath: "title") as? String, forKey: "title")
        
        if let dateStr = json.value(forKeyPath: "date") as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let timeZone = TimeZone(identifier: "America/New_York") {
                dateFormatter.timeZone = timeZone
            }
            podcast.setValue(dateFormatter.date(from: dateStr), forKey: "date")
        }
        
        return isNewData
    }
}

extension MBPodcast: Detailable {
    
}
