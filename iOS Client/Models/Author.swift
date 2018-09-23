//
//  Author.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

protocol AuthorDAO {
    func getAuthorById(_ authorId: Int) -> Author?
}

struct Author {
    var authorId: Int
    var name: String
    var info: String
}
