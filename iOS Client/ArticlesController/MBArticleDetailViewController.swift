//
//  ArticleDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/12/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import ReSwift
import WebKit

class MBArticleDetailViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var selectedArticle: MBArticle?
    
    static func instantiateFromStoryboard(article: MBArticle?) -> MBArticleDetailViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticleDetailController") as! MBArticleDetailViewController
        // swiftlint:enable force_cast
        
        vc.selectedArticle = article
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        configureBackButton()
    }
    
    func configureWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        
        view = webView
        
        if let content = self.selectedArticle?.content {
            webView.loadHTMLString(content, baseURL: nil)
        }
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToArticles(sender:)))
    }
    
    @objc func backToArticles(sender: AnyObject) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let cssString = "body { font-size: xx-large; color: #000 }"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
}
