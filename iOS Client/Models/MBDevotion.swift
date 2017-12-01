//
//  MBDevotion.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/4/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation


struct MBDevotion: Codable, Detailable {
    var date: String
    var text: String
    var verse: String
    var verseText: String
    
    var dateComponentsForNotification: DateComponents? {
        guard let devotionDay = Formatters.devotionDateFormatter.date(from: self.date), let calendar = MBDevotion.calendar else {
            return nil
        }
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 30
        dateComponents.year = calendar.component(NSCalendar.Unit.year, from: devotionDay)
        dateComponents.month = calendar.component(NSCalendar.Unit.month, from: devotionDay)
        dateComponents.day = calendar.component(NSCalendar.Unit.day, from: devotionDay)
        return dateComponents
    }
    
    private static let calendar: NSCalendar? = {
        return NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)
    }()
}

struct LoadedDevotion: Codable, Detailable {
    var date: String
    var text: String
    var verse: String
    var verseText: String
    var read: Bool
    
    init(devotion: MBDevotion, read: Bool) {
        date = devotion.date
        text = devotion.text
        verse = devotion.verse
        verseText = devotion.verseText
        self.read = read
    }
    
    var devotion: MBDevotion {
        return MBDevotion(date: date, text: text, verse: verse, verseText: verseText)
    }
}
