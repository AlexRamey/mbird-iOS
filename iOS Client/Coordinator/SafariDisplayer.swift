//
//  SafariDisplayer.swift
//  iOS Client
//
//  Created by Alex Ramey on 1/31/18.
//  Copyright © 2018 Mockingbird. All rights reserved.
//

import Foundation
import SafariServices

protocol SafariDisplayer : SFSafariViewControllerDelegate {
    var overlay: URL? { get set }
    var navigationController: UINavigationController  { get }
}

extension SafariDisplayer {
    func displaySafariVC(forURL url: URL?) {
        if self.overlay == nil, let overlay = url {
            self.overlay = overlay
            let overlayVC = SFSafariViewController(url: overlay)
            overlayVC.delegate = self
            self.navigationController.present(overlayVC, animated: true, completion: nil)
        } else if self.overlay != nil, url == nil {
            self.overlay = nil
            self.navigationController.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - SafariViewControllerDelegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        MBStore.sharedStore.dispatch(SelectedArticleLink(url: nil))
    }
}
