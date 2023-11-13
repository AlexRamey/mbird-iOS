//
//  ArticleDetailViewController.swift
//  iOS Client
//
//  Created by Jonathan Witten on 10/12/17.
//  Copyright © 2017 Mockingbird. All rights reserved.
//

import UIKit
import WebKit
import Nuke

class MBArticleDetailViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var selectedArticle: Article?
    var articleDAO: ArticleDAO?
    var categoryContext: String?
    weak var delegate: ArticleDetailDelegate?
    var baseURL = URL(string: "about:blank")
    
    static func instantiateFromStoryboard(article: Article?, categoryContext: String?, dao: ArticleDAO?) -> MBArticleDetailViewController {
        // swiftlint:disable force_cast
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ArticleDetailController") as! MBArticleDetailViewController
        // swiftlint:enable force_cast
        viewController.articleDAO = dao
        viewController.selectedArticle = article
        viewController.categoryContext = categoryContext
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        
        configureWebView()
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
            
            var cssString: String = ""
            do {
                if let cssPath = Bundle.main.path(forResource: "MB", ofType: "css") {
                    cssString = try String(contentsOfFile: cssPath).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                print("error: unable to load css string")
            }
            
            let cssHead = "<style>\(cssString)</style>"
            let head = "<head>\n\(contentTypeHead)\n\(viewPortHead)\n\(cssHead)\n</head>"
            
            // <style>
            let titleFontSize = UIFont.preferredFont(forTextStyle: .headline).pointSize * 1.35
            let authorFontSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 0.80
            let bodyFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize * 0.80
            let style = ""
                + "<style>\n"
                + "p.title{font-size: \(titleFontSize)pt;}\n"
                + "p.author{font-size: \(authorFontSize)pt;}\n"
                + "body{font-size: \(bodyFontSize)pt;}\n"
                + "</style>"
            
            
            // <body>
            var info: [String] = []
            if let category = self.categoryContext ?? self.selectedArticle?.categories.first?.name {
                info.append(category.uppercased())
            }
            if let date = self.selectedArticle?.getDate() {
                var longDate = DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
                if let idx = longDate.index(of: ",") {
                    longDate = String(longDate.prefix(upTo: idx))
                }
                info.append(longDate.uppercased())
            }
            
            let meta: String = info.joined(separator: " | ")
            let title: String = self.selectedArticle?.title ?? "Untitled 👀"
            let author: String = self.selectedArticle?.authorOverride ?? (self.selectedArticle?.author?.name ?? "Mockingbird Staff")
            let articleHeader = """
                <p class=""></p>
                <p class="meta">\(meta)</p>
                <p class="title">\(title)</p>
                <p class="author">by \(author)</p>
                <p class="dots">.....................</p>
            """
            let body = "<body>" + articleHeader + content + "</body>"

            // full page
            let fullContent = head + style + body
            webView.loadHTMLString(fullContent, baseURL: self.baseURL)
            
        }
    }
    
    func configureRightBarButtons() {
        let bookmarkItem = UIBarButtonItem(image: UIImage(named: "bookmark-item"), style: .plain, target: self, action: #selector(self.bookmarkArticle(sender:)))
        
        // let shareItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(self.shareArticle(sender:)))
        
        let shareItem = UIBarButtonItem(image: UIImage(named: "share-button"), style: .plain, target: self, action: #selector(self.shareArticle(sender:)))
        
        var items = [shareItem]
        if self.tabBarController?.selectedIndex != 1 {
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
        
        if let bookmarkErr = dao.bookmarkArticle(article) {
            self.popAlertWithMessage(errMessage + ": \(bookmarkErr)")
            return
        }
        
        self.popAlertWithMessage("bookmarked!")
    }
    
    private func popAlertWithMessage(_ msg: String) {
        let alert = UIAlertController(title: "Done", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        self.present(alert, animated: true) {
            self.perform(#selector(MBArticleDetailViewController.dismissAlert), with: nil, afterDelay: 1.0)
        }
    }
    
    @objc private func dismissAlert() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let dstURL = navigationAction.request.url,
            navigationAction.navigationType == .linkActivated,
            !dstURL.isLocalFragment(prefix: self.baseURL?.absoluteString) {
            decisionHandler(.cancel) // we're handling it manually
            if let delegate = self.delegate {
                delegate.selectedURL(url: dstURL)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}

protocol ArticleDetailDelegate: class {
    func selectedURL(url: URL)
}
