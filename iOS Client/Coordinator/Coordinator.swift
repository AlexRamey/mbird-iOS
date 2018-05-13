//
//  Coordinator.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/30/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift

protocol Coordinator: class {
    var childCoordinators: [Coordinator] { get set }
    var rootViewController: UIViewController { get }
    func start()
    func build(newRoute: [RouteComponent])
    var route: [RouteComponent] { get set }
    var tab: Tab { get }
}

extension Coordinator {
    /// Add a child coordinator to the parent
    func addChildCoordinator(childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    /// Remove a child coordinator from the parent
    func removeChildCoordinator(childCoordinator: Coordinator) {
        self.childCoordinators = self.childCoordinators.filter { $0 !== childCoordinator }
    }
    
    func build(newRoute: [RouteComponent]) {
        guard let root = self.rootViewController as? UINavigationController else { return }
        var rootViewControllers = root.viewControllers
        print("Current Route: \(route)")
        print("New Route: \(newRoute)")
        for (newRouteIndex, newComponent) in newRoute.enumerated() {
            if newRouteIndex > route.count - 1 { //case: more controllers in new route so push onto nav stack
                root.pushViewController(newComponent.viewController(forTab: self.tab)!, animated: true)
            } else if newComponent != route[newRouteIndex] { //case: differing routes so replace top of stack with new route
                let newTopOfStack = newRoute[newRouteIndex...].flatMap { $0.viewController(forTab: self.tab)}
                rootViewControllers.removeLast(route.count - newRouteIndex)
                root.setViewControllers(rootViewControllers, animated: true)
                newTopOfStack.forEach {
                    root.pushViewController($0, animated: true)
                }
                // Time to return.
                // Note: we just overwrote current route with the newRoute from the point of disagreement onward.
                // We are done and want to return here.
                // If newRoute was shorter than currentRoute, then we don't want the code below
                // to execute and pop off controllers we just added
                return
            }
        }
        
        // case: newRoute is a prefix of the current route, so pop off the end of current to match
        if newRoute.count < route.count {
            rootViewControllers.removeLast(route.count - newRoute.count)
            root.setViewControllers(rootViewControllers, animated: true)
        }
    }
}
