//
//  BankMFATableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/2/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class BankMFATableViewController: UITableViewController {
    
    var selectedBank = [String: String]()
    var mfaInfo = [String: String]()

    @IBOutlet weak var bankLogo: UIImageView!
    @IBOutlet weak var mfaTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: selectedBank["logo"]!)
        bankLogo.imageFromServerURL(url) {
            // Do something
        }
        
        title = selectedBank["bank_name"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            guard let token = mfaInfo["access_token"], let answer = mfaTextField.text else {
                showAlert(message: "Please enter an answer to the security question.")
                return
            }
            
            API().answerMFA(access_token: token, answer: answer, { (response) in
                if let success = response as? Bool, success == true {
                    DispatchQueue.main.async {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                } else if let mfa = response as? [String: String] {
                    DispatchQueue.main.async {
                        self.mfaInfo = mfa
                        self.mfaTextField.text = nil
                        self.tableView.reloadData()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Your security answer was not correct. Please try again.")
                    }
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return mfaInfo["message"]
        }
        return nil
    }
}
