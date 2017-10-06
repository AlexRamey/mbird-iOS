//
//  MBDeserializable.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import CoreData

protocol MBDeserializable {
    static func deserialize(json: NSDictionary, intoContext managedContext: NSManagedObjectContext) -> Error?
}

//protocol ArticleLoadState {
//    var isCachedDataOnDisk: Bool { get set }
//    var isLoading: Bool { get set }
//}

