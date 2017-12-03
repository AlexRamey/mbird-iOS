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
    
    var day: Date? {
        return LoadedDevotion.devotionDateFormatter.date(from: self.date)
    }
    var formattedMonthDay: String? {
        if let date = self.day, let day = LoadedDevotion.calendar?.components(.day, from: date).day {
            return String(describing: day)
        } else {
            return nil
        }
    }
    var formattedMonth: String? {
        if let date = self.day, let monthInt = LoadedDevotion.calendar?.components(.day, from: date).month {
            return LoadedDevotion.getMonth(fromInt: monthInt)
        } else {
            return nil
        }
    }
    
    static func getMonth(fromInt: Int) -> String {
        return LoadedDevotion.devotionDateFormatter.monthSymbols[fromInt-1]
    }
    
    var dateComponentsForNotification: DateComponents? {
        guard let devotionDay = LoadedDevotion.devotionDateFormatter.date(from: self.date), let calendar = LoadedDevotion.calendar else {
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
    
    static let devotionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-DD"
        return formatter
    }()
}
