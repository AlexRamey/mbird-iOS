//
//  MBAuthor+Custom.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import CoreData
import Foundation

extension MBAuthor {
    static let entityName: String = "Author"
    
    // deserialize accepts an NSDictionary and deserializes the object into the provided
    // managedObjectContext. It returns an error if something goes wrong.
    // If the author already existed, then it updates its fields from the new json
    // values. If no author with the json's id value already existed, a new one is
    // created and inserted into the managedContext.
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) throws -> Bool {
        var isNewData: Bool = false
        
        guard let idArg = json.object(forKey: "id") as? Int32 else {
            throw(MBDeserializationError.contractMismatch(msg: "unable to cast json 'id' into an Int32"))
        }
        
        let predicate = NSPredicate(format: "authorID == %d", idArg)
        let fetchRequest = NSFetchRequest<MBAuthor>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedAuthor: MBAuthor? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedAuthor = fetchedEntities.first
        } catch {
            throw(MBDeserializationError.fetchError(msg: "error while fetching author with id: \(idArg)"))
        }
        
        if resolvedAuthor == nil {
            print("new author!")
            isNewData = true
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedAuthor = NSManagedObject(entity: entity, insertInto: managedContext) as? MBAuthor
        }
        
        guard let author = resolvedAuthor else {
            throw(MBDeserializationError.contextInsertionError(msg: "unable to resolve author with id: \(idArg) into managed context"))
        }
        
        author.setValue(json.object(forKey: "id") as? Int32, forKey: "authorID")
        author.setValue(json.object(forKey: "description") as? String, forKey: "info")
        author.setValue(json.object(forKey: "name") as? String, forKey: "name")
        
        return isNewData
    }
    
}
