//
//  ArticleDTO.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

struct ArticleDTO: Codable {
    var articleId: Int
    var date: String
    var link: String
    var title: Content
    var authorId: Int
    var imageId: Int
    var content: Content
    var categoryIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case articleId      =   "id"
        case date           =   "date_gmt"
        case link
        case title
        case authorId       =   "author"
        case imageId        =   "featured_media"
        case content
        case categoryIds    =   "categories"
    }
    
    func toDomain() -> Article {
        return Article(id: self.articleId, date: self.date, link: self.link, title: self.title.rendered, authorId: self.authorId, author: nil, imageId: self.imageId, imageUrl: nil, content: self.content.rendered, categoryIds: self.categoryIds, categories: [])
    }
}

struct Content: Codable {
    var rendered: String
    
    enum CodingKeys: String, CodingKey {
        case rendered
    }
}
