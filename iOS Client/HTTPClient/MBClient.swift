//
//  MBClient.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/1/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

class MBClient: NSObject {
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    // Endpoints
    private let baseURL = "https://www.mbird.com/wp-json/wp/v2"
    private let articlesEndpoint = "/posts"
    private let categoriesEndpoint = "/categories"
    private let authorsEndpoint = "/users"
    private let mediaEndpoint = "/media"
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
    
    func getRecentArticles(inCategories categories: [Int], offset: Int, pageSize: Int, before: String?, after: String?, asc: Bool) -> Promise<[Article]> {
        return Promise { fulfill, reject in
            var categoriesArg = ""
            if categories.count > 0 {
                categoriesArg = categories.reduce("&categories=") { (result, elem) -> String in
                    return "\(result)\(elem),"
                }
                categoriesArg.removeLast()
            }
            var beforeArg = ""
            if let beforeDate = before {
                beforeArg = "&before=\(beforeDate)"
            }
            var afterArg = ""
            if let afterDate = after {
                afterArg = "&after=\(afterDate)"
            }
            let orderArg = "&order=" + (asc ? "asc" : "desc")
            let urlString = "\(baseURL)\(articlesEndpoint)?per_page=\(pageSize)&offset=\(offset)\(categoriesArg)\(beforeArg)\(afterArg)\(orderArg)"
            print("URL: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                reject(NetworkRequestError.invalidURL(url: urlString))
                return
            }
            
            print("firing getArticles request")
            getDataFromURL(url) { (data, err) in
                guard let payload = data.first, err == nil else {
                    reject(err ?? NetworkRequestError.failedPagingRequest(msg: "no first page :("))
                    return
                }
                
                var articles: [ArticleDTO] = []
                do {
                    articles = try self.decoder.decode([ArticleDTO].self, from: payload)
                } catch {
                    reject(error)
                    return
                }
                
                let domainArticles = articles.map({ (dto) -> Article in
                    return dto.toDomain()
                })
                
                fulfill(domainArticles)
            }
        }
    }
    
    func getPodcast(url: URL) -> Promise<Data> {
        return Promise { fulfill, reject in
            getDataFromURL(url) { data, error in
                if let err = error {
                    reject(err)
                } else if let data = data.first {
                    fulfill(data)
                } else {
                    reject(NetworkRequestError.networkError(msg: "Did not receive any valid data"))
                }
            }
        }
    }
    
    func searchArticlesWithCompletion(query: String, completion: @escaping ([Article], Error?) -> Void ) {
        let scheme = "https"
        let host = "www.mbird.com"
        let path = "/wp-json/wp/v2/posts"
        let queryItemPerPage = URLQueryItem(name: "per_page", value: "10")
        let queryItemSearch = URLQueryItem(name: "search", value: query)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = [queryItemPerPage, queryItemSearch]
        
        guard let url = urlComponents.url else {
            completion([], NetworkRequestError.invalidURL(url: urlComponents.string ?? ""))
            return
        }
        
        getDataFromURL(url) { (data, err) in
            guard let payload = data.first, err == nil else {
                completion([], err)
                return
            }
            
            var articles: [ArticleDTO] = []
            do {
                articles = try self.decoder.decode([ArticleDTO].self, from: payload)
            } catch {
                print(error)
                completion([], error)
                return
            }
            
            let domainArticles = articles.map({ (dto) -> Article in
                return dto.toDomain()
            })
            
            completion(domainArticles, nil)
        }
    }
    
    private func getDataFromURL(_ url: URL, withCompletion completion: @escaping ([Data], Error?) -> Void ) {
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
            
            if let resourceData = data {
                completion([resourceData], nil)
            } else {
                completion([], nil)
            }
        }.resume()
    }
    
    // getCategories makes a single request for the first page of category data.
    // After this request comes back, it examines the x-wp-totalpages response header to
    // determine how many pages of data exist. It then fires off concurrent requests for all
    // pages of category data. It invokes the passed-in completion with an array of response data
    // and optionally an error if one occurred at any point in the process.
    func getCategories() -> Promise<[Category]> {
        return Promise { fulfill, reject in
            let urlString = "\(baseURL)\(categoriesEndpoint)\(urlArgs)"
            let urlStringWithPageOne = "\(urlString)1"
            guard let url = URL(string: urlStringWithPageOne) else {
                reject(NetworkRequestError.invalidURL(url: urlStringWithPageOne))
                return
            }
            
            print("firing initial getCategories request")
            self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
                self.pagingHandler(url: urlString, data: data, resp: resp, err: err, completion: { (pages, err) in
                    if let err = err {
                        reject(err)
                        return
                    }
                    
                    var categories: [CategoryDTO] = []
                    for page in pages {
                        do {
                            let pageOfCategories = try self.decoder.decode([CategoryDTO].self, from: page)
                            categories.append(contentsOf: pageOfCategories)
                        } catch {
                            reject(error)
                            return
                        }
                    }
                    
                    let domainCategories = categories.map({ (dto) -> Category in
                        return dto.toDomain()
                    })
                    
                    fulfill(domainCategories)
                })
            }.resume()
        }
    }
    
    // getAuthors makes a single request for the first page of author data.
    // After this request comes back, it examines the x-wp-totalpages response header to
    // determine how many pages of data exist. It then fires off concurrent requests for all
    // pages of author data. It invokes the passed-in completion with an array of response data
    // and optionally an error if one occurred at any point in the process.
    func getAuthors() -> Promise<[Author]> {
        return Promise { fulfill, reject in
            let urlString = "\(baseURL)\(authorsEndpoint)\(urlArgs)"
            let urlStringWithPageOne = "\(urlString)1"
            guard let url = URL(string: urlStringWithPageOne) else {
                reject(NetworkRequestError.invalidURL(url: urlStringWithPageOne))
                return
            }
            
            print("firing initial getAuthors request")
            self.session.dataTask(with: url) { (data: Data?, resp: URLResponse?, err: Error?) in
                self.pagingHandler(url: urlString, data: data, resp: resp, err: err, completion: { (pages, err) in
                    if let err = err {
                        reject(err)
                        return
                    }
                    
                    var authors: [AuthorDTO] = []
                    for page in pages {
                        do {
                            let pageOfAuthors = try self.decoder.decode([AuthorDTO].self, from: page)
                            authors.append(contentsOf: pageOfAuthors)
                        } catch {
                            reject(error)
                            return
                        }
                    }

                    let domainAuthors = authors.map({ (dto) -> Author in
                        return dto.toDomain()
                    })
                    
                    fulfill(domainAuthors)
                })
            }.resume()
        }
    }
    
    func getPodcasts(for stream: PodcastStream) -> Promise<[PodcastDTO]> {
        guard let url = URL(string: stream.rawValue) else {
            return Promise(error: NetworkRequestError.invalidURL(url: stream.rawValue))
        }
        
        print("firing get podcasts request")
        let request = URLRequest(url: url)
        
        return self.session.dataTask(with: request).asDataAndResponse().then { (data: Data, _: URLResponse?) -> [PodcastDTO] in
            let parser = XMLParser(data: data)
            let xmlParserDelegate = PodcastXMLParsingDelegate()
            parser.delegate = xmlParserDelegate
            parser.parse()
            return xmlParserDelegate.podcasts
        }
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
        
        var filteredKeys = httpResponse.allHeaderFields.keys.filter { (key) -> Bool in
            guard let strKey = key as? String else {
                return false
            }
            return strKey.lowercased() == "x-wp-totalpages"
        }
        
        guard filteredKeys.count > 0,
              let wpTotalPages = httpResponse.allHeaderFields[filteredKeys[0]] as? String,
              let numPages = Int(wpTotalPages) else {
            completion([], NetworkRequestError.missingResponseHeaders(msg: "x-wp-totalpages header was missing"))
            return
        }
        
        if numPages == 1 {
            // we are done
            if let data = data {
                completion([data], nil)
                return
            } else {
                completion([], NetworkRequestError.networkError(msg: "an unknown error occurred"))
                return
            }
        }
        
        var dataTasks: [URLSessionDataTask] = []
        var results: [Data?] = [data]
        let serialQueue = DispatchQueue(label: "syncpoint")
        for index in 2...numPages {
            let urlString = "\(url)\(index)"
            guard let url = URL(string: urlString) else {
                completion([], NetworkRequestError.invalidURL(url: urlString))
                return
            }
            
            dataTasks.append(self.session.dataTask(with: url) { (data: Data?, _: URLResponse?, _: Error?) in
                serialQueue.async {
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
            if let data = result {
                retVal.append(data)
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

extension MBClient: ImageDAO {
    func getImagesById(_ ids: [Int], completion: @escaping ([Image]) -> Void) {
        guard ids.count > 0 else {
            completion([])
            return
        }
        
        let serialQueue = DispatchQueue(label: "imageProcessor")
        
        var jobCount = ids.count
        var results: [Image] = []
        
        ids.forEach { (imageId) in
            self.getImageById(imageId, completion: { (image) in
                serialQueue.async {
                    if let image = image {
                        results.append(image)
                    }
                    jobCount -= 1
                    if jobCount == 0 {
                        completion(results)
                    }
                }
            })
        }
    }
    
    func getImageById(_ imageId: Int, completion: @escaping (Image?) -> Void) {
        let urlString = "\(baseURL)\(mediaEndpoint)/\(imageId)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        print("firing get media url request: \(imageId)")
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
            
            var json: Any
            do {
                json = try JSONSerialization.jsonObject(with: mediaData, options: .allowFragments)
            } catch let error as NSError {
                print("Could not get media object. \(error), \(error.userInfo)")
                completion(nil)
                return
            }
            
            // keypaths for the image urls
            let keyPaths: [String] = [
                "media_details.sizes.thumbnail.source_url"
            ]
            
            guard let arr = json as? NSDictionary else {
                completion(nil)
                return
            }
            var thumbnailURL: URL? = nil
            if let thumbURL = arr.value(forKeyPath: keyPaths[0]) as? String {
                thumbnailURL = URL(string: thumbURL)
            }
            
            completion(Image(imageId: imageId, thumbnailUrl: thumbnailURL))
            }.resume()
    }
}
