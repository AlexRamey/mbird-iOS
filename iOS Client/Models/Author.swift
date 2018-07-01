//
//  Author.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

protocol AuthorDAO {
    func getAuthorById(_ id: Int) -> Author?
}

struct Author {
    var id: Int
    var name: String
    var info: String
}
