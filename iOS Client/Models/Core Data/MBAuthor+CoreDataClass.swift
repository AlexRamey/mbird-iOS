//
//  MBAuthor+CoreDataClass.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//
//

import Foundation
import CoreData


public class MBAuthor: NSManagedObject {
    static let entityName: String = "Author"
    
    class func newAuthor(fromAuthor from: Author, inContext managedContext: NSManagedObjectContext) -> MBAuthor? {
        let predicate = NSPredicate(format: "authorID == %d", from.id)
        let fetchRequest = NSFetchRequest<MBAuthor>(entityName: self.entityName)
        fetchRequest.predicate = predicate
        
        var resolvedAuthor: MBAuthor? = nil
        do {
            let fetchedEntities = try managedContext.fetch(fetchRequest)
            resolvedAuthor = fetchedEntities.first
        } catch {
            print("Error fetching author \(from.id) from core data: \(error)")
            return nil
        }
        
        if resolvedAuthor == nil {
            let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: managedContext)!
            resolvedAuthor = NSManagedObject(entity: entity, insertInto: managedContext) as? MBAuthor
        }
        
        guard let author = resolvedAuthor else {
            return nil
        }
        
        author.authorID = Int32(from.id)
        author.info = from.info
        author.name = from.name
        return author
    }
    
    func toDomain() -> Author {
        return Author(id: Int(self.authorID), name: self.name ?? "mockingbird", info: self.info ?? "")
    }
}
