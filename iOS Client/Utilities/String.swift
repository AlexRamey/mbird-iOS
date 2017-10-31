//
//  String.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/29/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

extension String {
    //This is pretty much copy paste from SO
    func convertHtml() -> NSAttributedString {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html,
                                                                .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
}
