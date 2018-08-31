//
//  CategoryDTO.swift
//  iOS Client
//
//  Created by Alex Ramey on 8/29/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

struct CategoryDTO: Codable {
    var categoryId: Int
    var parentId: Int
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case categoryId   =   "id"
        case parentId     =   "parent"
        case name
    }
    
    func toDomain() -> Category {
        return Category(id: categoryId, name: name, parentId: parentId)
    }
}
