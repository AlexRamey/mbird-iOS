//
//  AppDelegate.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import AVKit
import UIKit
import CoreData
import PromiseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    lazy var coreDataStack = CoreDataStack(modelName: "iOS_Client")
    var appCoordinator: AppCoordinator!
    private lazy var articlesStore: MBArticlesStore = {
        return MBArticlesStore(context: self.coreDataStack.privateQueueContext)
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        registerDefaults()
        styleNavBar()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        // inject dependencies
        let managedObjectContext = coreDataStack.managedContext
        let articleStore = MBArticlesStore(context: managedObjectContext)
        let articleDAO: ArticleDAO = articleStore
        let authorDAO: AuthorDAO = articleStore
        let categoryDAO: CategoryDAO = articleStore
        
        self.appCoordinator = AppCoordinator(window: self.window!, articleDAO: articleDAO, authorDAO: authorDAO, categoryDAO: categoryDAO, managedObjectContext: managedObjectContext)
        self.appCoordinator.start()
        
        application.setMinimumBackgroundFetchInterval(MBConstants.SECONDS_IN_A_DAY)
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        coreDataStack.saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveContext()
    }
    
    /*
     registerDefaults() sets initial values for user preferences in the Registration Domain
     of UserDefaults, which is an in-memory store. If the user later selects preference values,
     they will be saved in the persistent Application Domain. Values is the Application Domain
     will always trump their counterparts in the Registration Domain.
     */
    func registerDefaults(){
        let defaults = [ MBConstants.SELECTED_CATEGORY_NAME_KEY : MBConstants.MOST_RECENT_CATEGORY_NAME ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    func styleNavBar() {
        let attrs = [
            NSAttributedStringKey.foregroundColor: UIColor.MBOrange,
            NSAttributedStringKey.font: UIFont(name: "AvenirNext-Bold", size: 18.0)
        ]
        
        UINavigationBar.appearance().titleTextAttributes = attrs
        UINavigationBar.appearance().barTintColor = UIColor.white
    }
}
