//
//  DeserializationError.swift
//  iOS Client
//
//  Created by Alex Ramey on 10/15/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation

public enum MBDeserializationError: Error {
    case contractMismatch(msg: String)
    case fetchError(msg: String)
    case contextInsertionError(msg: String)
}
