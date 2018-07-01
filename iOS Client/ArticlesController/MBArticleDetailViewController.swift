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
import Nuke

class MBArticleDetailViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var selectedArticle: Article?
    var articleDAO: ArticleDAO?
    
    static func instantiateFromStoryboard(article: Article?, dao: ArticleDAO?) -> MBArticleDetailViewController {
        // swiftlint:disable force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticleDetailController") as! MBArticleDetailViewController
        // swiftlint:enable force_cast
        vc.articleDAO = dao
        vc.selectedArticle = article
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        
        configureWebView()
        configureBackButton()
        configureRightBarButtons()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contentSizeDidChange(_:)),
                                               name: NSNotification.Name.UIContentSizeCategoryDidChange,
                                               object: nil)
    }
    
    @objc private func contentSizeDidChange(_ notification: Notification) {
        configureWebView()
    }
    
    func configureWebView() {
        if let content = self.selectedArticle?.content {
            // <head>
            let contentTypeHead = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
            let viewPortHead = "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
            let cssHead = "<link rel=\"stylesheet\" type=\"text/css\" href=\"MB.css\" />"
            let head = "<head>\n\(contentTypeHead)\n\(viewPortHead)\n\(cssHead)\n</head>"
            
            // <style>
            let titleFontSize = UIFont.preferredFont(forTextStyle: .headline).pointSize * 0.80
            let authorFontSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 0.80
            let bodyFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize * 0.80
            let style = ""
                + "<style>\n"
                + "p.title{font-size: \(titleFontSize)pt;}\n"
                + "p.author{font-size: \(authorFontSize)pt;}\n"
                + "body{font-size: \(bodyFontSize)pt;}\n"
                + "</style>"
            
            
            // <body>
            let title: String = self.selectedArticle?.title ?? "Untitled 👀"
            let author: String = self.selectedArticle?.author?.name ?? "Mockingbird Staff"
            let articleHeader = """
                <p class="title">\(title)</p>
                <p class="author">by \(author)</p>
                <p class="dots">.....................</p>
            """
            let body = "<body>" + articleHeader + content + "</body>"

            // full page
            let fullContent = head + style + body
            
            // baseURL is used by the wkWebView to resolve relative links
            // Here, we point it straight to our css file referred to in the css header
            let baseURL = NSURL.fileURL(withPath: Bundle.main.path(forResource: "MB", ofType: "css")!)
            
            webView.loadHTMLString(fullContent, baseURL: baseURL)
            
        }
    }
    
    func configureBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .done, target: self, action: #selector(self.backToArticles(sender:)))
    }
    
    @objc func backToArticles(sender: AnyObject) {
        MBStore.sharedStore.dispatch(PopCurrentNavigation())
    }
    
    func configureRightBarButtons() {
        let bookmarkItem = UIBarButtonItem(image: UIImage(named: "bookmark-item"), style: .plain, target: self, action: #selector(self.bookmarkArticle(sender:)))
        
        let shareItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(self.shareArticle(sender:)))
        
        var items = [shareItem]
        if self.tabBarController?.selectedIndex != Tab.bookmarks.rawValue {
            // if not on bookmarks tab, show bookmark item
            items.append(bookmarkItem)
        }
        
        self.navigationItem.rightBarButtonItems = items
    }
    
    @objc func shareArticle(sender: AnyObject) {
        guard let linkToShare = self.selectedArticle?.link else {
            return
        }
        
        // set up activity view controller
        let activityViewController = UIActivityViewController(activityItems: [ linkToShare ], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [
            .airDrop,
            .assignToContact,
            .openInIBooks,
            .postToFlickr,
            .postToVimeo,
            .print,
            .saveToCameraRoll
        ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func bookmarkArticle(sender: AnyObject) {
        let errMessage = "unable to bookmark article"
        guard let dao = self.articleDAO else {
            self.popAlertWithMessage(errMessage)
            return
        }
        
        self.selectedArticle?.isBookmarked = true
        guard let article = self.selectedArticle else {
            self.popAlertWithMessage(errMessage)
            return
        }
        
        if let _ = dao.saveArticle(article) {
            self.popAlertWithMessage(errMessage)
            return
        }
        
        self.popAlertWithMessage("bookmarked!")
    }
    
    private func popAlertWithMessage(_ msg: String) {
        let alert = UIAlertController(title: "Done", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let dstURL = navigationAction.request.url,
            navigationAction.navigationType == .linkActivated {
            MBStore.sharedStore.dispatch(SelectedArticleLink(url: dstURL))
            decisionHandler(.cancel) // we're handling it manually
        } else {
            decisionHandler(.allow)
        }
    }
}
