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
    
    static func getMonth(fromInt: Int) -> String {
        switch fromInt {
        case 1:
            return "January"
        case 2:
            return "February"
        case 3:
            return "March"
        case 4:
            return "April"
        case 5:
            return "May"
        case 6:
            return "June"
        case 7:
            return "July"
        case 8:
            return "August"
        case 9:
            return "September"
        case 10:
            return "October"
        case 11:
            return "November"
        case 12:
            return "December"
        default:
            return ""
        }
    }
}
