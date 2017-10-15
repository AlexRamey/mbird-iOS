//
//  MBCategory+Custom.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/6/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import CoreData
import Foundation

extension MBCategory {
    static let entityName: String = "Category"
    
    // deserialize accepts an NSDictionary and deserializes the object into the provided
    // managedObjectContext. It returns an error if something goes wrong.
    // If the category already existed, then it updates its fields from the new json
    // values. If no category with the json's id value already existed, a new one is
    // created and inserted into the managedContext.
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) throws -> Bool {
        var isNewData: Bool = false
        
        guard let idArg = json.object(forKey: "id") as? Int32 else {
            throw(MBDeserializationError.contractMismatch(msg: "unable to cast json 'id' into an Int32"))
        }
        
        let predicate = NSPredicate(format: "categoryID == %d", idArg)
        let fetchRequest = NSFetchRequest<MBCategory>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedCategory: MBCategory? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedCategory = fetchedEntities.first
        } catch {
            throw(MBDeserializationError.fetchError(msg: "error while fetching category with id: \(idArg)"))
        }
        
        if resolvedCategory == nil {
            print("new category!")
            isNewData = true
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedCategory = NSManagedObject(entity: entity, insertInto: managedContext) as? MBCategory
        }
        
        guard let category = resolvedCategory else {
            throw(MBDeserializationError.contextInsertionError(msg: "unable to resolve category with id: \(idArg) into managed context"))
        }
        
        category.setValue(json.object(forKey: "id") as? Int32, forKey: "categoryID")
        category.setValue(json.object(forKey: "parent") as? Int32, forKey: "parent")
        category.setValue(json.object(forKey: "name") as? String, forKey: "name")
        return isNewData
    }
    
}
