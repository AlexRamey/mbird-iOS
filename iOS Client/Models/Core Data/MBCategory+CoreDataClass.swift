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
    
    class func newCategory(fromCategory from: Category, inContext managedContext: NSManagedObjectContext) -> MBCategory? {
        let predicate = NSPredicate(format: "categoryID == %d", from.id)
        let fetchRequest = NSFetchRequest<MBCategory>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedCategory: MBCategory? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedCategory = fetchedEntities.first
        } catch {
            print("Error fetching category \(from.id) from core data: \(error)")
            return nil
        }
        
        if resolvedCategory == nil {
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedCategory = NSManagedObject(entity: entity, insertInto: managedContext) as? MBCategory
        }
        
        guard let category = resolvedCategory else {
            return nil
        }
        
        category.categoryID = Int32(from.id)
        category.parentID = Int32(from.parentId)
        category.name = from.name
        return category
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
