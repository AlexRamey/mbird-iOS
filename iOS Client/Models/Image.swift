//
//  Image.swift
//  iOS Client
//
//  Created by Alex Ramey on 6/30/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

struct Image {
    var id: Int
    var thumbnailUrl: URL?
}

protocol ImageDAO {
    func getImageById(_ id: Int, completion: @escaping (Image?) -> Void)
    func getImagesById(_ ids: [Int], completion: @escaping ([Image]) -> Void)
}
