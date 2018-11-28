//
//  URL.swift
//  iOS Client
//
//  Created by Alex Ramey on 11/27/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation

extension URL {
    // used to detect fragment links to other portions of the page
    // in an article's content
    func isLocalFragment(prefix: String?) -> Bool {
        let result = self.absoluteString.hasPrefix("\(prefix ?? "")%23")
        return result
    }
}
