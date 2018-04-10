//
//  UIView.swift
//  iOS Client
//
//  Created by Jonathan Witten on 3/24/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

protocol LoadableNibByClassName { }

extension LoadableNibByClassName {
    static var nibName: String {
        return String(describing: Self.self)
    }
    
    static func loadInstance() -> Self {
        let allViewsInNib = Bundle.main.loadNibNamed(self.nibName, owner: self, options: nil)
        // swiftlint:disable force_cast
        return allViewsInNib?.first as! Self
        // swiftlint:enable force_cast
    }
}
