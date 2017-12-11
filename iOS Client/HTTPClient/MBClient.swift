//
//  MBClient.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/1/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

class MBClient: NSObject {
    private let session: URLSession
    
    // Endpoints
    private let baseURL = "https://www.mbird.com/wp-json/wp/v2"
    private let articlesEndpoint = "/posts"
    private let categoriesEndpoint = "/categories"
    private let authorsEndpoint = "/users"
    private let mediaEndpoint = "/media"
    private let podcastsEndpoint = "https://www.mbird.com/feed/podcast/"
    private let numResultsPerPage = 20
    private let urlArgs: String
    
    override init() {
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = true
        config.httpAdditionalHeaders = ["Accept": "application/json"]
        self.session = URLSession(configuration: config)
        urlArgs = "?per_page=\(numResultsPerPage)&page="
        
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
        let urlString = "\(baseURL)\(articlesEndpoint)?per_page=50"
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
        let urlStringWithPageOne = "\(urlString)1"
        guard let url = URL(string: urlStringWithPageOne) else {
            completion([], NetworkRequestError.invalidURL(url: urlStringWithPageOne))
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
        let urlStringWithPageOne = "\(urlString)1"
        guard let url = URL(string: urlStringWithPageOne) else {
            completion([], NetworkRequestError.invalidURL(url: urlStringWithPageOne))
            return
        }
        
        print("firing initial getAuthors request")
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            self.pagingHandler(url: urlString, data: data, resp: resp, err: err, completion: completion)
        }.resume()
    }
    
    func getPodcastsWithCompletion(completion: @escaping (Data?, Error?) -> Void ) {
        guard let url = URL(string: podcastsEndpoint) else {
            completion(nil, NetworkRequestError.invalidURL(url: podcastsEndpoint))
            return
        }
        
        print("firing get podcasts request")
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            if let e = err {
                completion(nil, e)
            } else if let response = data {
                completion(response, nil)
            } else {
                completion(nil, NetworkRequestError.networkError(msg: "did not receive a response"))
            }
        }.resume()
    }
    
    func getJSONFile(name: String, completion: @escaping (Data?, Error?) -> Void ) {
        do {
            if let file = Bundle.main.url(forResource: name, withExtension: "json") {
                let data = try Data(contentsOf: file)
                completion(data, nil)
            } else {
                completion(nil, NetworkRequestError.badResponse(status: 404))
            }
        } catch {
            print(error.localizedDescription)
            completion(nil, NetworkRequestError.badResponse(status: 404))
        }
    }

    func getImageData(imageID: Int, completion: @escaping (Data?) -> Void) {
        let urlString = "\(baseURL)\(mediaEndpoint)/\(imageID)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        print("firing get media request: \(imageID)")
        self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
            guard self.wasDataTaskSuccessful(resp: resp, err: err) else {
                completion(nil)
                return
            }
            
            // Process Data
            guard let mediaData = data else {
                completion(nil)
                return
            }
            
            var json : Any
            do {
                json = try JSONSerialization.jsonObject(with: mediaData, options: .allowFragments)
            } catch let error as NSError {
                print("Could not get media object. \(error), \(error.userInfo)")
                completion(nil)
                return
            }
            
            if let arr = json as? NSDictionary, let imageLink = arr.value(forKeyPath: "media_details.sizes.thumbnail.source_url") as? String {
                guard let imageUrl = URL(string: imageLink) else {
                    completion(nil)
                    return
                }
                print("firing get image request: \(imageID)")
                self.session.dataTask(with: imageUrl) { (data: Data?, resp: URLResponse?, err: Error?) in
                    guard self.wasDataTaskSuccessful(resp: resp, err: err) else {
                        completion(nil)
                        return
                    }
                    
                    // Process Data
                    guard let imageData = data else {
                        completion(nil)
                        return
                    }
                    
                    completion(imageData)
                }.resume()
            } else {
                completion(nil)
            }
            
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
        for i in 2...numPages {
            let urlString = "\(url)\(i)"
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
    
    private func wasDataTaskSuccessful(resp: URLResponse?, err: Error?) -> Bool {
        // Connectivity errors
        if err != nil {
            return false
        }
        
        // HTTP Errors
        if let httpResponse = resp as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            
            if statusCode < 200 || statusCode > 299 {
                return false
            }
        }
        
        return true
    }
}
