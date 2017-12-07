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
        configureBookmarkButton()
    }
    
    func configureBookmarkButton() {
        let barButton = UIBarButtonItem(title: "Bookmark", style: .plain, target: self, action: #selector(MBArticleDetailViewController.bookmark(_:)))
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func configureWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        if let content = self.selectedArticle?.content {
            print(content)
            let cssHead: String = "<head>\n<link rel=\"stylesheet\" type=\"text/css\" href=\"MB.css\">\n</head>\n"
            
            let title: String = self.selectedArticle?.title ?? "Untitled 👀"
            let author: String = self.selectedArticle?.author?.name ?? "Mockingbird Staff"
            let articleHeader = "<p class=\"title\">\(title)</p><p class=\"author\">By \(author)</p>"
            let fullContent = cssHead + "<body>" + articleHeader + content + "</body>"
            
            // baseURL is used by the wkWebView to resolve relative links
            // Here, we point it straight to our css file referred to in the css header
            let baseURL = NSURL.fileURL(withPath: Bundle.main.path(forResource: "MB", ofType: "css")!)
            
            webView.loadHTMLString(fullContent, baseURL: baseURL)
            
        }
    }
    
   @objc func bookmark(_ sender: Any) {
        do {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let container = appDelegate.persistentContainer,
                let article = selectedArticle else {
                return
            }
            
            try MBStore().bookmark(article: article, persistentContainer: container)
            // TODO: Dispatch an action here to update state if we change our models to be structs
            // We don't have to do this now because our models are reference types, so marking it bookmarked in CoreData is enough
            // But this doesn't exactly follow the immutable state aspect of Redux
        } catch {
            print("Error saving bookmark")
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
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let dstURL = navigationAction.request.url,
            dstURL.absoluteString.range(of: "http") != nil,
            dstURL.absoluteString.range(of: "youtube.com/embed") == nil,
            dstURL.absoluteString.range(of: "embed.vevo.com") == nil {
            MBStore.sharedStore.dispatch(SelectedArticleLink(url: dstURL))
            decisionHandler(.cancel) // we're handling it manually
        } else {
            decisionHandler(.allow)
        }
    }
}
