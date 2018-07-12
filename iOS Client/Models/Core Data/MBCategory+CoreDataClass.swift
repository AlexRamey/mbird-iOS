//
//  MBCategory+CoreDataClass.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


public class MBCategory: NSManagedObject {
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
        category.setValue(json.object(forKey: "parent") as? Int32, forKey: "parentID")
        category.setValue(json.object(forKey: "name") as? String, forKey: "name")
        return isNewData
    }
    
    // There are multiple top-level categories (whose parentID is 0). The rest are children.
    // This method follows the parent links until it encounters a top-level category,
    // which it returns. If called on a top-level category, this method returns the
    // receiver.
    func getTopLevelCategory() -> MBCategory? {
        return self.getTopLevelCategoryInternal(loopGuard: 0)
    }
    
    private func getTopLevelCategoryInternal(loopGuard: Int) -> MBCategory? {
        if loopGuard > 50 {
            // just in case they create a cycle . . .
            return nil
        }
        
        if self.parentID == 0 {
            return self
        } else {
            return self.parent?.getTopLevelCategoryInternal(loopGuard:loopGuard+1) ?? nil
        }
    }
    
    func getAllDescendants() -> [MBCategory] {
        var retVal: Set<MBCategory> = []
        var queue: [MBCategory] = (self.children?.allObjects as? [MBCategory]) ?? []
        
        var loopGuard = 0 // just in case they create a cycle
        while let current = queue.popLast() {
            guard loopGuard < 1000 else {
                return Array(retVal)
            }
            loopGuard += 1
            
            retVal.insert(current)
            if let children = current.children?.allObjects as? [MBCategory] {
                queue.insert(contentsOf: children, at: 0)
            }
        }
        
        return Array(retVal)
    }
    
    func toDomain() -> Category {
        return Category(id: Int(self.categoryID), name: self.name ?? "", parentId: Int(self.parentID))
    }
}
