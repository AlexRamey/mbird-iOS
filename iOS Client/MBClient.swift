//
//  MBClient.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/1/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation

class MBClient : NSObject {
    private let session: URLSession
    
    // Endpoints
    private let baseURL = "https://www.mbird.com/wp-json/wp/v2"
    private let articlesEndpoint = "/posts"
    private let categoriesEndpoint = "/categories"
    private let authorsEndpoint = "/users"
    
    override init(){
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Accept": "application/json"]
        self.session = URLSession(configuration: config)
        
        super.init()
    }
    
    func getArticlesWithCompletion(completion: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        guard let url = URL(string: "\(baseURL)\(articlesEndpoint)") else {
            return
        }
        
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            completion(data, resp, err)
        }.resume()
    }
    
    func getAuthorsWithCompletion(completion: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        guard let url = URL(string: "\(baseURL)\(authorsEndpoint)") else {
            return
        }
        
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            completion(data, resp, err)
            }.resume()
    }
    
    func getCategoriesWithCompletion(completion: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        guard let url = URL(string: "\(baseURL)\(categoriesEndpoint)") else {
            return
        }
        
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            completion(data, resp, err)
            }.resume()
    }
}
