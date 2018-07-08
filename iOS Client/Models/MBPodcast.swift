//
//  MBPodcast.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/10/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

struct PodcastDTO: Codable {
    let author: String?
    let duration: String?
    let guid: String?
    let image: String?
    let keywords: String?
    let summary: String?
    let pubDate: String?
    let title: String?
}

struct Podcast: Codable {
    let author: String?
    let duration: String?
    let guid: String?
    let image: String
    let keywords: String?
    let summary: String?
    let pubDate: Date
    let title: String?
    let feed: PodcastStream
}

public enum PodcastStream: String, Codable {
    case pz = "https://pzspodcast.fireside.fm/rss"
    case mockingCast = "https://themockingcast.fireside.fm/rss"
    case mockingPulpit = "http://www.mbird.com/feed/podcast/"
    case talkingbird = "https://talkingbird.fireside.fm/rss"
    
    var imageName: String {
        switch self {
        case .pz: return "pzcast"
        case .mockingPulpit: return "mockingpulpit"
        case .mockingCast: return "mockingcast"
        case .talkingbird: return "talkingbird"
        }
    }
    
    var title: String {
        switch self {
        case .pz: return "PZ's Podcast"
        case .mockingCast: return "The Mockingcast"
        case .mockingPulpit: return "The Mockingpulpit"
        case .talkingbird: return "Talkingbird"
        }
    }
}

