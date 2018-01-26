//
//  WithdrawFundsTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/9/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class WithdrawFundsTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var walletBalanceLabel: UILabel!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var bankLabel: UILabel!
    
    var accountBalance: Float = 0.00
    var bankAccount: [String: Any]?
    var walletAccount: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //withdrawButton.isEnabled = false
        getWalletAccount()
        getBankAccount()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func withdrawFunds(_ sender: Any) {
        guard accountBalance > 0.99 else {
            showAlert(message: "You must have at least $1.00 to make a withdrawal.")
            return
        }
        
        guard let walletId = walletAccount?["_id"] as? String else {
            showAlert(message: "A wallet account has not been set up to deposit funds to.")
            return
        }
        
        guard let bankId = bankAccount?["_id"] as? String else {
            showAlert(message: "Please select an ACH account with enough funds available.")
            return
        }
        
        API().withdrawFunds(from: walletId, to: bankId, amount: 20) {
            if ($0) {
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                self.showAlert(message: "We were unable to process this withdrawal request.")
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func updateAvailableBalance(_ amount: String?) {
        if let newBalance = Float(amount ?? "0.00") {
            self.accountBalance = newBalance
        }
        
        DispatchQueue.main.async {
            self.walletBalanceLabel.text = "$\(String(format: "%.2f", self.accountBalance)) available"
            //self.withdrawButton.isEnabled = (self.accountBalance > 0.99)
        }
    }
    
    func refreshAccounts() {
        
        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: String] {
            print("WALLET LOADED: \(wallet)")
            self.updateAvailableBalance(balance["amount"])
        } else {
            self.updateAvailableBalance("0.00")
        }
        
        var bankLabel = "---"
        if let node = self.bankAccount, let info = node["info"] as? [String: Any] {
            let nodeName = info["bank_name"] as? String ?? "Example Checking Account"
            let lastFour = info["account_num"] as? String ?? "0000"
            bankLabel = "\(nodeName) ••••\(lastFour)"
        }
        
        DispatchQueue.main.async {
            self.bankLabel.text = bankLabel
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FundingSourceTableViewController {
            vc.source = self.bankLabel.text
        }
    }
}
