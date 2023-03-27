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
    case mockingPulpit = "https://themockingpulpit.fireside.fm/rss"
    case talkingbird = "https://talkingbird.fireside.fm/rss"
    case sameOldSong = "https://thesameoldsong.fireside.fm/rss"
    case brothersZahl = "https://thebrotherszahl.fireside.fm/rss"
    case terribleParables = "https://terribleparables.fireside.fm/rss"
    
    var imageName: String {
        switch self {
        case .pz: return "pzcast"
        case .mockingPulpit: return "mockingpulpit"
        case .mockingCast: return "mockingcast"
        case .talkingbird: return "talkingbird"
        case .sameOldSong: return "sameoldsong"
        case .brothersZahl: return "brotherszahl"
        case .terribleParables: return "terribleParables"
        }
    }
    
    var title: String {
        switch self {
        case .pz: return "PZ's Podcast"
        case .mockingCast: return "The Mockingcast"
        case .mockingPulpit: return "The Mockingpulpit"
        case .talkingbird: return "Talkingbird"
        case .sameOldSong: return "Same Old Song"
        case .brothersZahl: return "The Brothers Zahl"
        case .terribleParables: return "Terrible Parables"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .pz: return "PZ's Podcast"
        case .mockingCast: return "Mockingcast"
        case .mockingPulpit: return "Mockingpulpit"
        case .talkingbird: return "Talkingbird"
        case .sameOldSong: return "Same Old Song"
        case .brothersZahl: return "Brothers Zahl"
        case .terribleParables: return "Terrible Parables"
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
        case .sameOldSong:
            return "A weekly discussion of the texts assigned for Sunday in the lectionary, hosted by Jacob Smith and Aaron Zimmerman. As always, grace abounds. Not just for preachers!"
        case .brothersZahl:
            return "A long overdue collaboration between John, David and Simeon Zahl, three siblings engaged in \"the God business\"--one as a writer, one as a professor, one as a priest. They tackle some big subjects, in hopes of sketching an overarching picture of grace and everyday life (and making some decent jokes in the process)"
        case .terribleParables:
            return "Sometimes the Good Book doesn’t sound all that great. Fortunately, first impressions can be misleading, and the surprise of grace may be hiding in plain sight. Welcome to Terrible Parables, the podcast where a scholar, a pastor, and an anxious Christian look for good news in passages of scripture that appear strange or unnerving. Brought to you by Mockingbird Ministries and hosted by Cali Yee, along with Bryan Jarrell and Todd Brewer. Audio production by TJ Hester."
        }
    }
    
    var dateFormat: String {
        // this used to vary per podcast before they were all hosted on Fireside
        return "E, d MMM yyyy HH:mm:ss Z"
    }
}
