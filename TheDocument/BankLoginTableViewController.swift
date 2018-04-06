//
//  BankLoginTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/2/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class BankLoginTableViewController: UITableViewController {
    
    var selectedBank = [String: String]()
    var mfaInfo = [String: String]()
    var loadingBank = false

    @IBOutlet weak var bankLogo: UIImageView!
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var userPwTextField: UITextField!
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bankLogo.imageFromServerURL(URL(string: selectedBank["logo"]!)) {
            // Do something
        }
        
        title = selectedBank["bank_name"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("Selected row...")
        guard loadingBank == false else { return }
        log.debug("Not loading bank")
        
        if indexPath.section == 2 {
            guard let bankId = userIdTextField.text, let bankPassword = userPwTextField.text, let bankName = selectedBank["bank_code"], bankId != "", bankPassword != "" else {
                showAlert(message: "Please fill out your username and password.")
                return
            }
            
            // Set bank loading to true
            self.loadingBank = true
            self.loadingSpinner.startAnimating()
            self.continueLabel.text = "Connecting to bank..."
            self.navigationItem.hidesBackButton = true
            
            API().linkBankAccount(bank_id: bankId, bank_password: bankPassword, bank_name: bankName, { (response) in
                DispatchQueue.main.async {
                    log.debug("linkBankAccount: \(response)")
                    if let json = response as? [String: Any], let success = json["success"] as? Bool, success == true {
                        // Successful link
                        if let mfa = json["mfa"] as? [String: String] {
                            self.mfaInfo = mfa
                            self.performSegue(withIdentifier: "showBankMFA", sender: self)
                        } else {
                            // No MFA required, pop back to accounts list
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    } else {
                        log.error("Error linking bank: \(response)")
                        self.showAlert(message: "Could not link bank account")
                    }
                    
                    // Set no longer loading bank
                    self.loadingBank = false
                    self.loadingSpinner.stopAnimating()
                    self.continueLabel.text = "Continue"
                    self.navigationItem.hidesBackButton = false
                }
            })
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "showBankMFA") {
            let destViewController = segue.destination as! BankMFATableViewController
            destViewController.selectedBank = selectedBank
            destViewController.mfaInfo = mfaInfo
        }
    }

}
