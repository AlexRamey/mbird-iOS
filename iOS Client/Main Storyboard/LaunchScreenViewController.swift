//
//  LaunchScreenViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/31/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

class LaunchScreenViewController: UIViewController {
    static func instantiateFromStoryboard() -> LaunchScreenViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LaunchScreenViewController") as! LaunchScreenViewController
        // swiftlint:enable force_cast
        return vc
    }
}
