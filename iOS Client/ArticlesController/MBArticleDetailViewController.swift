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
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
        
        configureWebView()
        
        configureBackButton()
        
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
            print(content)
            // <head>
            let contentTypeHead = "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
            let viewPortHead = "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
            let cssHead = "<link rel=\"stylesheet\" type=\"text/css\" href=\"MB.css\" />"
            let head = "<head>\n\(contentTypeHead)\n\(viewPortHead)\n\(cssHead)\n</head>"
            
            // <style>
            let titleFontSize = UIFont.preferredFont(forTextStyle: .headline).pointSize
            let authorFontSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
            let bodyFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
            let style = ""
                + "<style>\n"
                + "p.title{font-size: \(titleFontSize)pt;}\n"
                + "p.author{font-size: \(authorFontSize)pt;}\n"
                + "body{font-size: \(bodyFontSize)pt;}\n"
                + "</style>"
            
            
            // <body>
            let title: String = self.selectedArticle?.title ?? "Untitled 👀"
            let author: String = self.selectedArticle?.author?.name ?? "Mockingbird Staff"
            let articleHeader = "<p class=\"title\">\(title)</p><p class=\"author\">By \(author)</p>"
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
