//
//  SelectCategoryViewController.swift
//  iOS Client
//
//  Created by Alex Ramey on 8/4/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import UIKit

class SelectCategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navItem: UINavigationItem!
    
    var categoryDAO: CategoryDAO!
    var categories: [Category] = []
    var currentSelection = ""
    let reuseIdentifier = "categoryCellResuseIdentifier"
    
    static func instantiateFromStoryboard(categoryDAO: CategoryDAO) -> SelectCategoryViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SelectCategoryVC") as! SelectCategoryViewController
        // swiftlint:enable force_cast
        viewController.categoryDAO = categoryDAO
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navItem.title = "SELECT CATEGORY"
        self.currentSelection = UserDefaults.standard.string(forKey: MBConstants.SELECTED_CATEGORY_NAME_KEY)!
        let mostRecent = Category(categoryId: -1, name: MBConstants.MOST_RECENT_CATEGORY_NAME, parentId: 0)
        self.categories = [mostRecent] + self.categoryDAO.getAllTopLevelCategories()
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissMe(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = self.categories[indexPath.row]
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) else {
            return UITableViewCell()
        }
        if category.name == self.currentSelection {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.textLabel?.text = category.name
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentSelection = self.categories[indexPath.row].name
        UserDefaults.standard.set(self.currentSelection, forKey: MBConstants.SELECTED_CATEGORY_NAME_KEY)
        self.tableView.reloadData()
        self.dismiss(animated: true, completion: nil)
    }
}
