//
//  MBClient.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/1/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation

class MBClient: NSObject {
    private let session: URLSession
    
    // Endpoints
    private let baseURL = "https://www.mbird.com/wp-json/wp/v2"
    private let articlesEndpoint = "/posts"
    private let categoriesEndpoint = "/categories"
    private let authorsEndpoint = "/users"
    private let numResultsPerPage = 20
    private let urlArgs: String
    
    override init() {
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Accept": "application/json"]
        self.session = URLSession(configuration: config)
        urlArgs = "?page=1&per_page=\(numResultsPerPage)&offset="
        
        super.init()
    }
    
    enum NetworkRequestError: Error {
        case invalidURL(url: String)
        case networkError(msg: String)
        case badResponse(status: Int)
        case missingResponseHeaders(msg: String)
        case failedPagingRequest(msg: String)
    }
    
    // getArticlesWithCompletion makes a single URL request for the 25 most recent posts
    // When the response is received, it calls the completion block with the resulting data and error
    func getArticlesWithCompletion(completion: @escaping ([Data], Error?) -> Void ) {
        let urlString = "\(baseURL)\(articlesEndpoint)?per_page=25"
        guard let url = URL(string: urlString) else {
            completion([], NetworkRequestError.invalidURL(url: urlString))
            return
        }
        
        print("firing getArticles request")
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            if let httpResponse = resp as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    completion([], NetworkRequestError.badResponse(status: httpResponse.statusCode))
                    return
                }
            }
            
            if let networkErr = err {
                completion([], NetworkRequestError.networkError(msg: networkErr.localizedDescription))
                return
            }
            
            if let articleData = data {
                completion([articleData], nil)
            } else {
                completion([], nil)
            }
        }.resume()
    }
    
    // getCategoriesWithCompletion makes a single request for the first page of category data.
    // After this request comes back, it examines the x-wp-totalpages response header to
    // determine how many pages of data exist. It then fires off concurrent requests for all
    // pages of category data. It invokes the passed-in completion with an array of response data
    // and optionally an error if one occurred at any point in the process.
    func getCategoriesWithCompletion(completion: @escaping ([Data], Error?) -> Void ) {
        let urlString = "\(baseURL)\(categoriesEndpoint)\(urlArgs)"
        let urlStringWithOffsetZero = "\(urlString)0"
        guard let url = URL(string: urlStringWithOffsetZero) else {
            completion([], NetworkRequestError.invalidURL(url: urlStringWithOffsetZero))
            return
        }
        
        print("firing initial getCategories request")
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            self.pagingHandler(url: urlString, data: data, resp: resp, err: err, completion: completion)
        }.resume()
    }
    
    // getAuthorsWithCompletion makes a single request for the first page of author data.
    // After this request comes back, it examines the x-wp-totalpages response header to
    // determine how many pages of data exist. It then fires off concurrent requests for all
    // pages of author data. It invokes the passed-in completion with an array of response data
    // and optionally an error if one occurred at any point in the process.
    func getAuthorsWithCompletion(completion: @escaping ([Data], Error?) -> Void ) {
        let urlString = "\(baseURL)\(authorsEndpoint)\(urlArgs)"
        let urlStringWithOffsetZero = "\(urlString)0"
        guard let url = URL(string: urlStringWithOffsetZero) else {
            completion([], NetworkRequestError.invalidURL(url: urlStringWithOffsetZero))
            return
        }
        
        print("firing initial getAuthors request")
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            self.pagingHandler(url: urlString, data: data, resp: resp, err: err, completion: completion)
        }.resume()
    }
    
    private func pagingHandler(url: String, data: Data?, resp: URLResponse?, err: Error?, completion: @escaping ([Data], Error?) -> Void) {
        
        if let networkErr = err {
            completion([], NetworkRequestError.networkError(msg: networkErr.localizedDescription))
            return
        }
        
        guard let httpResponse = resp as? HTTPURLResponse else {
            completion([], NetworkRequestError.networkError(msg: "an unknown error occurred"))
            return
        }
        
        if httpResponse.statusCode != 200 {
            completion([], NetworkRequestError.badResponse(status: httpResponse.statusCode))
            return
        }
        
        guard let wpTotalPages = httpResponse.allHeaderFields["x-wp-totalpages"] as? String, let numPages = Int(wpTotalPages) else {
            completion([], NetworkRequestError.missingResponseHeaders(msg: "x-wp-totalpages header was missing"))
            return
        }
        
        if numPages == 1 {
            // we are done
            if let d = data {
                completion([d], nil)
                return
            } else {
                completion([], NetworkRequestError.networkError(msg: "an unknown error occurred"))
                return
            }
        }
        
        var dataTasks: [URLSessionDataTask] = []
        var results: [Data?] = [data]
        for i in 1...numPages {
            let urlString = "\(url)\(i*self.numResultsPerPage)"
            guard let url = URL(string: urlString) else {
                completion([], NetworkRequestError.invalidURL(url: urlString))
                return
            }
            
            dataTasks.append(self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
                DispatchQueue.main.async {
                    results.append(data)
                    // results starts with the data from the initial response, hence dataTasks.count + 1
                    if results.count == dataTasks.count + 1 {
                        self.processBatchOfResults(results: results, completion: completion)
                    }
                }
            })
        }
        _ = dataTasks.map { elem in print("firing off data task"); elem.resume() }
    }
    
    private func processBatchOfResults(results: [Data?], completion: @escaping ([Data], Error?) -> Void) {
        var retVal: [Data] = []
        print("processing batch results")
        for result in results {
            if let d = result {
                retVal.append(d)
            }
        }
        
        
        if retVal.count != results.count {
            completion([], NetworkRequestError.failedPagingRequest(msg: "a request for paged data failed"))
            return
        }
        
        completion(retVal, nil)
    }
}
