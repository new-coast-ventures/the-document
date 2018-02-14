//
//  UserReviewViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 2/14/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class UserReviewViewController: UIViewController {

    @IBOutlet weak var okButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func okButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
