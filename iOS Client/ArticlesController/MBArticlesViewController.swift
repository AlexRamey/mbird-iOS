//
//  ViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/24/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit

class MBArticlesViewController: UIViewController {
    static func instantiateFromStoryboard() -> MBArticlesViewController {
        // swiftlint:disable force_cast
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticlesController") as! MBArticlesViewController
        // swiftlint:enable force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /******** START EXAMPLE ***********/
        
        // 1. the managed context has to be passed in (UIApplication should only be accessed from main thread)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Unable to get the app delegate!")
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // 2. Sync all the Data
        MBStore().syncAllData(context: managedContext) { (err: Error?) in
            if let syncErr = err {
                print(syncErr)
                return
            }
            
            print("Sync Success!")
            
            print("\nAUTHOR NAMES")
            print(MBStore().getAuthors(managedContext: managedContext).map { $0.name })
            print("\nAUTHOR IDS")
            print(MBStore().getAuthors(managedContext: managedContext).map { $0.authorID })
            
            print("\nCATEGORIES")
            print(MBStore().getCategories(managedContext: managedContext).map { $0.name })
            
            print("\nARTICLE TITLES")
            print(MBStore().getArticles(managedContext: managedContext).map { $0.title })
            print("\nARTICLE AUTHOR IDS")
            print(MBStore().getArticles(managedContext: managedContext).map { $0.authorID })
            print("\nARTICLE AUTHOR NAMES")
            print(MBStore().getArticles(managedContext: managedContext).map { $0.author?.name })
            
            print("\nARTICLE CATEGORY NAMES")
            let lists = MBStore().getArticles(managedContext: managedContext).map { $0.categories?.allObjects }
            for list in lists {
                if let cats = list as? [MBCategory] {
                    print(cats.map {$0.name})
                } else {
                    print("💩")
                }
            }
        }
        /********* END EXAMPLE ************/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
