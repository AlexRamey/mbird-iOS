//
//  Store.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/26/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift

class MBStore {
    static let sharedStore = Store(
        reducer: appReducer,
        state: nil,
        middleware: [MiddlewareFactory.loggingMiddleware])      // Middlewares are optional
}
