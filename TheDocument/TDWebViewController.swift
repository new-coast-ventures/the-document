//
//  TDWebViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 9/20/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit
import WebKit

class TDWebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webview: UIWebView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var url: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (url.absoluteString == "https://the-document-prod.herokuapp.com/privacy") {
            self.title = "Privacy Policy"
            loadPDF(titled: "privacy")
        } else if (url.absoluteString == "https://the-document-prod.herokuapp.com/terms") {
            self.title = "Terms of Use"
            loadPDF(titled: "terms")
        } else {
            webview.loadRequest(URLRequest(url: url))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadPDF(titled: String) {
        if let pdfURL = Bundle.main.url(forResource: titled, withExtension: "pdf", subdirectory: nil, localization: nil)  {
            do {
                let data = try Data(contentsOf: pdfURL)
                webview.load(data, mimeType: "application/pdf", textEncodingName: "", baseURL: url)
            }
            catch {
                // catch errors here
                webview.loadRequest(URLRequest(url: url))
            }
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        spinner.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        spinner.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        spinner.stopAnimating()
        log.error(error)
    }
}
