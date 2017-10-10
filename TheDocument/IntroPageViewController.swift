//
//  IntroPageViewController.swift
//  TheDocument
//


import UIKit

class IntroPageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    var imageURLString: String = ""
    var titleString: String = ""
    var bodyString: String = ""
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startActivityIndicator()
        imageView.imageFromServerURL(URL(string: imageURLString)){ [weak self] in
            self?.stopActivityIndicator()
        }
        titleLabel.text = titleString
        bodyLabel.text = bodyString
    }
}
