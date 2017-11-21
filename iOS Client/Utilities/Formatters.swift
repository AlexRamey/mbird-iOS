//
//  Formatters.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/14/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation

struct Formatters {
    
    static let devotionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-DD"
        return formatter
    }()
    
    static let calendar: NSCalendar? = {
       return NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)
    }()
}
