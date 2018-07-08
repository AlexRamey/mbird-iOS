//
//  NSPointerArrayExtension.swift
//  iOS Client
//
//  Created by Alex Ramey on 7/8/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//
// Credit: https://marcosantadev.com/swift-arrays-holding-elements-weak-references/

import Foundation

class WeakRef<T> where T: AnyObject {
    
    private(set) weak var value: T?
    
    init(value: T?) {
        self.value = value
    }
}
