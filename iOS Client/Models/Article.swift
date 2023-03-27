//
//  Article.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import PromiseKit

struct Article {
    var articleId: Int
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
    var authorOverride: String?
    
    mutating func resolveAuthor(dao: AuthorDAO) {
        self.author = dao.getAuthorById(authorId)
    }
    
    mutating func resolveCategories(dao: CategoryDAO) {
        self.categories = dao.getCategoriesById(self.categoryIds)
    }
    
    func getDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let timeZone = TimeZone(identifier: "GMT") {
            dateFormatter.timeZone = timeZone
        }
        return dateFormatter.date(from: self.date)
    }
}

protocol ArticleDAO {
    func downloadImageURLsForArticle(_ article: Article, withCompletion completion: @escaping (URL?) -> Void)
    func getLatestArticles(skip: Int) -> [Article]
    func getLatestCategoryArticles(categoryIDs: [Int], skip: Int) -> [Article]
    func bookmarkArticle(_ article: Article) -> Error?
    func nukeAndPave() -> Promise<[Article]>
    func saveArticles(articles: [Article]) -> Error?
}
