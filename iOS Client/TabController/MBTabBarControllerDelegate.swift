//
//  MBTabBarDelegate.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import ReSwift
import UIKit

class MBTabBarControllerDelegate: NSObject, UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        var selectedIndex = 0
        
        if let navController = viewController as? UINavigationController {
            if let title = navController.viewControllers[0].title {
                switch title {
                case "Articles":
                    selectedIndex = 0
                case "Bookmarks":
                    selectedIndex = 1
                default:
                    break
                }
            }
        }
        
        // Send off the Action
        MBStore.sharedStore.dispatch(NavigationActionSwitchTab(newIndex: selectedIndex))
        
        return false
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("this happenned")
    }
}
