//
//  ArticleTableViewRowCell.swift
//  iOS Client
//
//  Created by Alex Ramey on 12/5/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import Foundation
import UIKit
import Preheat
import Nuke

class ArticleTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    var articles: [MBArticle] = []
    let narrowItemReuseIdentifier = "narrowItemReuseIdentifier"
    let itemReuseIdentifier = "itemReuseIdentifier"
    let preheater = Nuke.Preheater()
    var controller: Preheat.Controller<UICollectionView>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.collectionView.register(UINib(nibName: "NarrowArticleItem", bundle: nil), forCellWithReuseIdentifier: narrowItemReuseIdentifier)
        self.collectionView.register(UINib(nibName: "ArticleItem", bundle: nil), forCellWithReuseIdentifier: itemReuseIdentifier)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8.0 // space between columns
        layout.minimumInteritemSpacing = 500.0 // space between rows (big to keep it all on one row)
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        self.collectionView.collectionViewLayout = layout
        
        controller = Preheat.Controller(view: collectionView)
        controller?.enabled = true
        controller?.handler = { [weak self] addedIndexPaths, removedIndexPaths in
            self?.preheat(added: addedIndexPaths, removed: removedIndexPaths)
        }
    }
    
    func preheat(added: [IndexPath], removed: [IndexPath]) {
        func requests(for indexPaths: [IndexPath]) -> [Request] {
            return indexPaths.flatMap({ (indexPath) -> Request? in
                guard let imageLink = articles[indexPath.item].imageLink, let url = URL(string: imageLink) else {
                    return nil
                }
                
                var request = Request(url: url)
                request.priority = .low
                return request
            })
        }
        preheater.startPreheating(with: requests(for: added))
        preheater.stopPreheating(with: requests(for: removed))
    }
    
    func configure(articles: [MBArticle]) {
        self.articles = articles
        self.setupLayout(forItemCount: articles.count)
        self.collectionView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
        self.collectionView.reloadData()
    }
    
    func setupLayout(forItemCount itemCount: Int) {
        guard let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        let screenWidth = UIScreen.main.bounds.width
        if itemCount == 1 {
            layout.itemSize = CGSize(width: (screenWidth - 8.0 * 3), height: 280.0)
        } else {
            layout.itemSize = CGSize(width: (screenWidth/2.0 - 8.0 * 3), height: 280.0)
        }
    }
}

extension ArticleTableViewCell {
    // MARK: - UICollectionViewDataSource Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = self.articles.count == 1 ? itemReuseIdentifier : narrowItemReuseIdentifier
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ArticleItem
        // swiftlint:enable force_cast
        cell.configure(article: self.articles[indexPath.item])
        return cell
    }
    
    // MARK: - UICollectionViewDelegateMethods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedArticle = self.articles[indexPath.item]
        let action = SelectedArticle(article: selectedArticle)
        MBStore.sharedStore.dispatch(action)
    }
}
