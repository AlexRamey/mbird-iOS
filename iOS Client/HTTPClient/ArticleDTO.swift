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
    var yoastHeadJson: YoastHeadJson?
    
    enum CodingKeys: String, CodingKey {
        case articleId      =   "id"
        case date           =   "date_gmt"
        case link
        case title
        case authorId       =   "author"
        case imageId        =   "featured_media"
        case content
        case categoryIds    =   "categories"
        case yoastHeadJson  =   "yoast_head_json"
    }
    
    func toDomain() -> Article {
        return Article(articleId: self.articleId, date: self.date, link: self.link, title: self.title.rendered, authorId: self.authorId, author: nil, imageId: self.imageId, image: nil, content: self.content.rendered, categoryIds: self.categoryIds, categories: [], isBookmarked: false, authorOverride: self.yoastHeadJson?.twitterMisc?["Written by"])
    }
}

struct Content: Codable {
    var rendered: String
    
    enum CodingKeys: String, CodingKey {
        case rendered
    }
}

struct YoastHeadJson: Codable {
    var twitterMisc: Dictionary<String, String>?
    
    enum CodingKeys: String, CodingKey {
        case twitterMisc = "twitter_misc"
    }
}
