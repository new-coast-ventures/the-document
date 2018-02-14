//
//  AddKYCTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 2/14/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class AddKYCTableViewController: UITableViewController {
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    var step: Int = 0
    var phoneNumber: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if step == 0 {
            return "Enter your number"
        } else {
            return "Enter verification code"
        }
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        if step == 0 {
            verifyButton.setTitle("Sending...", for: .normal)
            // Trigger 2FA with Oauth call
        } else {
            verifyButton.setTitle("Verifying...", for: .normal)
            // Send verification code to KYC patch
        }
    }
}
