//
//  AttachmentViewController.swift
//  toktiv
//
//  Created by Hafiz Saad on 29/08/2021.
//

import UIKit
import WebKit
import MBProgressHUD

class AttachmentViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView : WKWebView!
    var webViewURL = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        InterfaceManager.shared.showLoader()
        
        let url = URL(string: webViewURL)!
        let urlRequest = URLRequest(url: url)
        
        webView.load(urlRequest)
        webView.navigationDelegate = self
        // Do any additional setup after loading the view.
    }
    

    //MARK: - IBActions
    
    @IBAction func popThisController()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        InterfaceManager.shared.hideLoader()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
