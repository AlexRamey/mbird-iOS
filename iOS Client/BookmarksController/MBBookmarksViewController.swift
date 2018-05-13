//
//  MBBookmarksViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import CoreData

class MBBookmarksViewController: UIViewController {
    
    private let bookmarkCellIdentifier = "bookmarkCellReuseIdentifier"
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<MBArticle>!
    lazy var imageMakerQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Maker Queue"
        return queue
    }()
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    static func instantiateFromStoryboard() -> MBBookmarksViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BookmarksController") as! MBBookmarksViewController
        // swiftlint:enable force_cast
        vc.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(named: "bookmark-unselected"), selectedImage: UIImage(named: "bookmark-selected"))
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Bookmarks"
        self.isEditing = false
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        let fetchRequest: NSFetchRequest<MBArticle> = MBArticle.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isBookmarked == %@", NSNumber(value: true))
        
        let sort = NSSortDescriptor(key: #keyPath(MBArticle.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Internal
extension MBBookmarksViewController {
    func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        if let bookmarkCell = cell as? BookmarkCell {
            bookmarkCell.configure(article: fetchedResultsController.object(at: indexPath), withQueue: imageMakerQueue)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension MBBookmarksViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? BookmarkCell {
                configure(cell: cell, for: indexPath!)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - UITableViewDataSource
extension MBBookmarksViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: bookmarkCellIdentifier, for: indexPath)
        configure(cell: cell, for: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.isEditing
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let article = fetchedResultsController.object(at: indexPath)
            article.isBookmarked = false
            do {
                try article.managedObjectContext?.save()
            } catch {
                print("Error bookmarking article: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension MBBookmarksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedArticle = fetchedResultsController.object(at: indexPath)
        let action = SelectedArticle(article: selectedArticle)
        MBStore.sharedStore.dispatch(action)
    }
}
