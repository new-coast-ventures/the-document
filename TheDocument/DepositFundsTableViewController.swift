//
//  DepositFundsTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/9/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class DepositFundsTableViewController: UITableViewController, UITextFieldDelegate {
    
    var bankAccount: [String: Any]?
    var walletAccount: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getBankAccount()
        getWalletAccount()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func depositFunds(_ sender: Any) {
        guard let walletId = walletAccount?["_id"] as? String else {
            showAlert(message: "A wallet account has not been set up to deposit funds to.")
            return
        }
        
        guard let bankId = bankAccount?["_id"] as? String else {
            showAlert(message: "Please select an ACH account with enough funds available.")
            return
        }
        
        //guard let amount =
        
        API().depositFunds(from: bankId, to: walletId, amount: 20) {
            if ($0) {
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                self.showAlert(message: "Something went wrong and we weren't able to complete the deposit.")
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func refreshAccounts() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func getWalletAccount() {
        print("Getting wallet...")
        if let wallet = currentUser.wallet, let _ = wallet["_id"] as? String {
            walletAccount = wallet
            self.refreshAccounts()
        } else {
            API().getWallet({ (success) in
                self.walletAccount = currentUser.wallet
                self.refreshAccounts()
            })
        }
    }
    
    func getBankAccount() {
        API().getLinkedAccounts { success in
            if let nodes = currentUser.nodes {
                self.bankAccount = nodes.first
                self.refreshAccounts()
            }
        }
    }
}
