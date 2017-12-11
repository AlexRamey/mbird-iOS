//
//  XMLParsingDelegate.swift
//  iOS Client
//
//  Created by Jonathan Witten on 12/9/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation


class PodcastXMLParsingDelegate: NSObject, XMLParserDelegate {
    var podcast: [String: String] = [:]
    var items: [[String:String]] = []
    var podcasts: [MBPodcast] = []
    var foundCharacters: String = ""
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundCharacters += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "title" {
            self.podcast["title"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "author" {
            self.podcast["itunes:author"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "description" {
            self.podcast["description"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "itunes:image" {
            self.podcast["image"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "guid" {
            self.podcast["guid"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "pubDate" {
            self.podcast["pubDate"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "itunes:keywords" {
            self.podcast["keywords"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "itunes:duration" {
            self.podcast["duration"] = self.foundCharacters.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if elementName == "item" {
            self.podcasts.append(dictToPod(dict: self.podcast))
            self.podcast = [:]
        }
        self.foundCharacters = ""
    }
    
    private func dictToPod(dict: [String: String]) -> MBPodcast {
       return MBPodcast(
        author: dict["author"],
        duration: dict["duration"],
        guid: dict["guid"],
        image: dict["image"],
        keywords: dict["keywords"],
        summary: dict["summary"],
        pubDate: dict["pubDate"],
        title: dict["title"]
    )
    }
}
