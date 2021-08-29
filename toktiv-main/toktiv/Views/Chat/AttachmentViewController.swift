//
//  AttachmentViewController.swift
//  toktiv
//
//  Created by Hafiz Saad on 29/08/2021.
//

import UIKit
import WebKit

class AttachmentViewController: UIViewController {
    
    @IBOutlet weak var webView : WKWebView!
    var webViewURL = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: webViewURL)!
        let urlRequest = URLRequest(url: url)
        
        webView.load(urlRequest)

        // Do any additional setup after loading the view.
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
