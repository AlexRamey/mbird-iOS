//
//  MBCategory+Custom.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/6/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import CoreData
import Foundation

extension MBCategory: MBDeserializable {
    static let entityName: String = "Category"
    
    // deserialize accepts an NSDictionary and deserializes the object into the provided
    // managedObjectContext. It returns an error if something goes wrong.
    // If the category already existed, then it updates its fields from the new json
    // values. If no category with the json's id value already existed, a new one is
    // created and inserted into the managedContext.
    public class func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) -> Error? {
        
        guard let idArg = json.object(forKey: "id") as? Int32 else {
            print("unable to cast json 'id' into an Int32")
            return NSError()
        }
        
        let predicate = NSPredicate(format: "categoryID == %d", idArg)
        let fetchRequest = NSFetchRequest<MBCategory>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedCategory: MBCategory? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedCategory = fetchedEntities.first
        } catch let error as NSError {
            print("An error: '\(error)' occurred during the fetch request for a single category")
            return error
        }
        
        if resolvedCategory == nil {
            print("new category!")
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedCategory = NSManagedObject(entity: entity, insertInto: managedContext) as? MBCategory
        }
        
        guard let category = resolvedCategory else {
            print("ERROR: Unable to resolve category!")
            return NSError()
        }
        
        category.setValue(json.object(forKey: "id") as? Int32, forKey: "categoryID")
        category.setValue(json.object(forKey: "parent") as? Int32, forKey: "parent")
        category.setValue(json.object(forKey: "name") as? String, forKey: "name")
        return nil
    }
    
}
