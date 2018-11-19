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
    
    var shortTitle: String {
        switch self {
        case .pz: return "PZ's Podcast"
        case .mockingCast: return "Mockingcast"
        case .mockingPulpit: return "Mockingpulpit"
        case .talkingbird: return "Talkingbird"
        }
    }
    
    var description: String {
        switch self {
        case .pz:
            return "Grace-based impressions and outré correlations from the author of Grace in Practice, Paul F.M. Zahl."
        case .mockingCast:
            return "A bi-weekly roundtable on culture, faith and grace, co-hosted by RJ Heijmen, Sarah Condon and David Zahl."
        case .mockingPulpit:
            return "Sermons from Mockingbird contributors, singing that “same song” of God’s grace in different keys, week after week."
        case .talkingbird:
            return "Your destination for talks given at Mbird events, both present and past. Subjects run the gamut from religion and theology to psychology and literature to pop culture and relationships and everything in between."
        }
    }
    
    var dateFormat: String {
        switch self {
        case .mockingPulpit:
            return "E, d MMM yyyy HH:mm:ss zzz"
        default:
            return "E, d MMM yyyy HH:mm:ss Z"
        }
    }
}
