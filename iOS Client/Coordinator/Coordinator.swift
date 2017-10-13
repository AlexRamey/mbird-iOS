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
    func build(newRoute: [Route])
    var route: [Route] { get set }
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
    
    func build(newRoute: [Route]) {
        guard let root = rootViewController as? UINavigationController else { return }
        
        var rootViewControllers = root.viewControllers
        for newRouteIndex in 0..<newRoute.count {
            if newRouteIndex > route.count - 1 { //case: more controllers in new route so push onto nav stack
                root.pushViewController(Route.viewController(forRoute: newRoute[newRouteIndex], inTab: Tab.tab(forCoordinator: self)!)!, animated: true)
                
            } else if newRoute[newRouteIndex] != route[newRouteIndex] { //case: differing routes so replace top of stack with new route
                let newTopOfStack = newRoute[newRouteIndex...].flatMap { Route.viewController(forRoute: $0, inTab: Tab.tab(forCoordinator: self)!)}
                rootViewControllers.removeLast(route.count - newRouteIndex)
                newTopOfStack.forEach {
                    root.pushViewController($0, animated: true)
                }
                break
            }
        }
        if newRoute.count < route.count { //case: less controllers in new route so pop off existing routes
            rootViewControllers.removeLast(route.count - newRoute.count)
        }
    }
    
    
}
