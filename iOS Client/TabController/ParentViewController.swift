//
//  ParentViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 8/31/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import UIKit

class ParentViewController: UIViewController {
    
    var initial: UIViewController!
    var content: UIViewController!
    
    static func build(_ initial: UIViewController, _ content: UIViewController) -> ParentViewController {
        let viewController = ParentViewController()
        viewController.initial = initial
        viewController.content = content
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(initial)
        addChildViewController(content)
        initial.didMove(toParentViewController: self)
        content.didMove(toParentViewController: self)
        pinToView(initial.view)
        pinToView(content.view)
        registerForLaunchingNotification()
    }
    
    private func registerForLaunchingNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(displayInitialView),
                                               name: NSNotification.Name.UIApplicationDidFinishLaunching,
                                               object: nil)
    }
    
    private func pinToView(_ child: UIView) {
        self.view.addSubview(child)
        child.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        child.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        child.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        child.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    @objc private func displayInitialView() {
        self.content.view.alpha = 0
        self.initial.view.alpha = 1
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: displayContentView)
    }
    
    private func displayContentView() {
        UIView.animate(withDuration: 0.5) {
            self.content.view.alpha = 1
            self.initial.view.alpha = 0
        }
    }
}
