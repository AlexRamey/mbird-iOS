//
//  Article.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

struct Article {
    var id: Int
    var date: String
    var link: String
    var title: String
    var authorId: Int
    var author: Author?
    var imageId: Int
    var image: Image?
    var content: String
    var categoryIds: [Int]
    var categories: [Category]
    var isBookmarked: Bool
    
    mutating func resolveAuthor(dao: AuthorDAO) {
        self.author  = dao.getAuthorById(authorId)
    }
    
    mutating func resolveCategories(dao: CategoryDAO) {
        self.categories = dao.getCategoriesById(self.categoryIds)
    }
}

protocol ArticleDAO {
    func saveArticle(_ article: Article) -> Error?
}
