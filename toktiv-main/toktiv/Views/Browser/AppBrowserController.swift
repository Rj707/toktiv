//
//  AppBrowserController.swift
//  toktiv
//
//  Created by Developer on 08/12/2020.
//

import Foundation
import UIKit
import WebKit

class AppBrowserController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView:WKWebView!
    @IBOutlet weak var activityIndicator:UIActivityIndicatorView!
    
    var urlString:String?
    var titleString:String?

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.isHidden = true
        self.webView.navigationDelegate = self
        
        if let validUrlString = self.urlString, let validURL = URL(string: validUrlString) {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            let request = URLRequest(url: validURL)
            webView.load(request)
        }
        
    }
    
    //MARK: - WebView Delegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicator.isHidden = true
        self.webView.isHidden = false
        self.activityIndicator.stopAnimating()
    }
    
    //MARK: - IBActions
    
    @IBAction func dismissMe() {
        self.dismiss(animated: true, completion: nil)
    }

}
