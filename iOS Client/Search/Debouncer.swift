//
//  Debouncer.swift
//  iOS Client
//
//  Created by Alex Ramey on 7/1/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//
// Credit: https://github.com/webadnan/swift-debouncer

import UIKit

class Debouncer: NSObject {
    var callback: ((UISearchController) -> ())
    var delay: Double
    weak var timer: Timer?
    
    init(delay: Double, callback: @escaping ((UISearchController) -> ())) {
        self.delay = delay
        self.callback = callback
    }
    
    func call(searchController: UISearchController) {
        timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(Debouncer.fireNow), userInfo: searchController, repeats: false)
        timer = nextTimer
    }
    
    @objc func fireNow(timer: Timer) {
        guard let searchController = timer.userInfo as? UISearchController else {
            return
        }
        self.callback(searchController)
    }
}
