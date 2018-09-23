//
//  AuthorDTO.swift
//  iOS Client
//
//  Created by Alex Ramey on 8/29/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

struct AuthorDTO: Codable {
    var authorId: Int
    var info: String
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case authorId   =   "id"
        case info       =   "description"
        case name
    }
    
    func toDomain() -> Author {
        return Author(authorId: authorId, name: name, info: info)
    }
}
