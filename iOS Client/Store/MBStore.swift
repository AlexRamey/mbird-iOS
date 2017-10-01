//
//  Store.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift
import CoreData

class MBStore: NSObject {
    static let sharedStore = Store(
        reducer: appReducer,
        state: nil,
        middleware: [MiddlewareFactory.loggingMiddleware])      // Middlewares are optional
    
    private let client: MBClient
    
    override init() {
        client = MBClient()
        super.init()
    }
    
    func getAuthors() -> [String] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Author")
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            return results.map({(author: NSManagedObject) -> String in
                return author.value(forKey: "name") as? String ?? ""
            })
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return []
        }
    }
    
    func fetchAuthors(completion: @escaping (Error?) -> Void) {
        client.getAuthorsWithCompletion { (data: Data?, _: URLResponse?, err: Error?) in
            if let jsonData = data {
                self.getAuthorsHandler(data: jsonData)
            }
            
            completion(err)
        }
    }
    
    // returns a handler for getAuthors response
    func getAuthorsHandler(data: Data) {
        var json : Any
        do {
            json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let arr = json as? [NSDictionary], let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let managedContext = appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Author", in: managedContext)!
                
                let managedObjects = arr.map({(jsonAuthor: NSDictionary) -> NSManagedObject in
                    let author = NSManagedObject(entity: entity, insertInto: managedContext)
                    author.setValue(jsonAuthor.object(forKey: "id") as? Int32, forKey: "id")
                    author.setValue(jsonAuthor.object(forKey: "description") as? String, forKey: "info")
                    author.setValue(jsonAuthor.object(forKey: "name") as? String, forKey: "name")
                    return author
                })
                try managedContext.save()
            }
        } catch {
            print(error)
        }
    }
}
