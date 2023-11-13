//
//  MBBookmarksViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 9/27/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import CoreData
import Nuke

class MBBookmarksViewController: UIViewController {
    
    private let bookmarkCellIdentifier = "bookmarkCellReuseIdentifier"
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<Bookmark>!
    lazy var imageMakerQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Maker Queue"
        return queue
    }()
    weak var delegate: ArticlesTableViewDelegate?
    var emptyLabel: UILabel?
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    static func instantiateFromStoryboard() -> MBBookmarksViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BookmarksController") as! MBBookmarksViewController
        // swiftlint:enable force_cast
        viewController.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(named: "bookmark-gray"), selectedImage: UIImage(named: "bookmark-selected"))
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\u{00B7}\u{00B7}\u{00B7}   BOOKMARKS   \u{00B7}\u{00B7}\u{00B7}"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Bookmarks", style: .plain, target: nil, action: nil)
        self.tabBarItem.title = "Bookmarks"
        
        self.isEditing = true
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        let fetchRequest: NSFetchRequest<Bookmark> = Bookmark.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Bookmark.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        
        setupBackgroundView()
    }
    
    private func setupBackgroundView() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true
        label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
        label.font = UIFont(name: "IowanOldStyle-Roman", size: 20.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "To bookmark a post, visit the one you'd like to save and tap the feather at the top of the screen. To remove, swipe left."
        label.isHidden = tableView.numberOfRows(inSection: 0) > 0
        emptyLabel = label
    }
}

// MARK: - Internal
extension MBBookmarksViewController {
    func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        if let bookmarkCell = cell as? BookmarkCell {
            let article = fetchedResultsController.object(at: indexPath)
            bookmarkCell.configure(article: article)
            if let link = article.thumbnailLink, let url = URL(string: link) {
                Manager.shared.loadImage(with: url, into: bookmarkCell.coverImageView)
            }
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
        self.emptyLabel?.isHidden = tableView.numberOfRows(inSection: 0) > 0
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
            article.managedObjectContext?.delete(article)
            do {
                try article.managedObjectContext?.save()
            } catch {
                print("Error un-bookmarking article: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension MBBookmarksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let delegate = self.delegate {
            let selectedArticle = fetchedResultsController.object(at: indexPath)
            delegate.selectedArticle(selectedArticle.toDomain(), categoryContext: nil)
        }
    }
}
