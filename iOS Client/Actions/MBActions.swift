//
//  MBActions.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

struct NavigationActionSwitchTab: Action {
    var newIndex: Int = 0
    
    init(newIndex: Int) {
        self.newIndex = newIndex
    }
}
