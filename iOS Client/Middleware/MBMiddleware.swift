//
//  MBMiddleware.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

struct MiddlewareFactory {
    
    // Logging Middleware
    static let loggingMiddleware: Middleware<Any> = { dispatch, getState in
        return { next in
            return { action in
                // perform middleware logic
                print("ACTION: \(type(of: action))")
                
                // call next middleware
                return next(action)
            }
        }
    }
    
    // Next Middleware . . .
    static let saveDevotionMiddleware: Middleware<Any> = { dispatch, getState in
        return { next in
            return { action in
                if let selectedDevotionAction = action as? SelectedDevotion {
                    do {
                        print("saving!")
                        var devotion = selectedDevotionAction.devotion
                        devotion.read = true
                        try MBDevotionsStore().replace(devotion: devotion)
                    } catch {
                        // There was an error saving devotion as read so reverse
                        print("Error marking devotion as read")
                        return // don't continue
                    }
                }
                return next(action)
            }
        }
    }
}
