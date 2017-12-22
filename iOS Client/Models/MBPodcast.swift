//
//  MBPodcast.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation

struct MBPodcast: Codable, Detailable {
    let author: String?
    let duration: String?
    let guid: String?
    let image: String?
    let keywords: String?
    let summary: String?
    let pubDate: String?
    let title: String?
}
