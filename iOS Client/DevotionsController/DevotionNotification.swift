//
//  DevotionNotification.swift
//  iOS Client
//
//  Created by Jonathan Witten on 11/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UserNotifications

class DevotionNotificationContent: UNMutableNotificationContent {
    var devotion: LoadedDevotion
    
    init(devotion: LoadedDevotion) {
        self.devotion = devotion
        super.init()
        self.title = devotion.verse
        self.body = "Read your daily devotion from Mockingbird"
        self.sound = UNNotificationSound.default()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
