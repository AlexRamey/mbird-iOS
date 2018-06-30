//
//  Category.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

protocol CategoryDAO {
    func getCategoriesById(_ ids: [Int]) -> [Category]
}

struct Category {
    var id: Int
    var name: String
    var parentId: Int
}
