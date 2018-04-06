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
    var isLoading = false

    @IBOutlet weak var bankLogo: UIImageView!
    @IBOutlet weak var mfaTextField: UITextField!
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
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
        guard isLoading == false else { return }
        
        if indexPath.section == 2 && indexPath.row == 0 {
            guard let token = mfaInfo["access_token"], let answer = mfaTextField.text, token != "", answer != "" else {
                showAlert(message: "Please enter an answer to the security question.")
                return
            }
            
            // Set bank loading to true
            self.isLoading = true
            self.loadingSpinner.startAnimating()
            self.continueLabel.text = "Submitting..."
            self.navigationItem.hidesBackButton = true
            
            API().answerMFA(access_token: token, answer: answer, { (response) in
                DispatchQueue.main.async {
                    if let mfa = response as? [String: String] {
                        self.mfaInfo = mfa
                        self.mfaTextField.text = nil
                        self.tableView.reloadData()
                    } else {
                        
                        let alert = UIAlertController(title: "Bank Account Linked!", message: "Your account was successfully linked. Please note it can take a few minutes before the account shows up in Linked Accounts.", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            self.navigationController?.popToRootViewController(animated: true)
                        }))
                        
                        self.present(alert, animated: true)
                    }
                    
                    // Set bank loading to true
                    self.isLoading = false
                    self.loadingSpinner.stopAnimating()
                    self.continueLabel.text = "Continue"
                    self.navigationItem.hidesBackButton = false
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
