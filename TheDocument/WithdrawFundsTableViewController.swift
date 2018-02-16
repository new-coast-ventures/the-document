//
//  WithdrawFundsTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/9/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class WithdrawFundsTableViewController: UITableViewController, UITextFieldDelegate, SelectedAccountProtocol {

    @IBOutlet weak var walletBalanceLabel: UILabel!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var bankLabel: UILabel!
    
    var accountBalance: Float = 0.00
    var bankAccount: [String: Any]?
    var walletAccount: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDoneButtonOnKeyboard()
        getWalletAccount()
        getBankAccount()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = bankAccount {
            self.refreshAccounts()
        }
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
        
        guard let amountString = amountTextField.text, let amount = Int(amountString), amount >= 1 else {
            showAlert(message: "Please enter a valid dollar amount. The minimum withdrawal amount is $1.")
            return
        }
        
        guard Float(amount) <= self.accountBalance else {
            showAlert(message: "The amount you requested is more than what you have in your wallet. Please update the amount.")
            return
        }
        
        let alertView = customAlert()
        alertView.addButton("Yes",backgroundColor: Constants.Theme.authButtonSelectedBGColor) { self.processWithdrawal() }
        alertView.addButton("No",backgroundColor: Constants.Theme.deleteButtonBGColor) {  /* cancel deposit */ }
        alertView.showInfo("Confirm Withdrawal", subTitle: "Withdrawals are subject to a $0.10 processing fee. Do you want to proceed with the withdrawal?")
    }
    
    func processWithdrawal() {
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
        
        guard let amountString = amountTextField.text, let amount = Int(amountString) else {
            showAlert(message: "Please enter a valid dollar amount")
            return
        }
        
        guard Float(amount) <= self.accountBalance else {
            showAlert(message: "The amount you requested is more than what you have in your wallet. Please update the amount.")
            return
        }
        
        API().withdrawFunds(from: walletId, to: bankId, amount: amount) {
            if ($0) {
                DispatchQueue.main.async {
                    self.showAlert(title: "Withdrawal Initiated", message: "Bank transfers initiated before 7 PM ET on business days will typically be available the next business day, but it can take up to 3 business days. Business days are Monday to Friday, excluding bank holidays.", closure: { action in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Something went wrong and we weren't able to complete the deposit.")
                }
            }
        }
    }
    
    func customAlert() -> NCVAlertView {
        return NCVAlertView(appearance: NCVAlertView.NCVAppearance(kTitleFont: UIFont(name: "OpenSans-Bold", size: 16)!,kTextFont: UIFont(name: "OpenSans", size: 14)!,kButtonFont: UIFont(name: "OpenSans-Bold", size: 14)!,showCloseButton: false, showCircularIcon: false, titleColor: Constants.Theme.authButtonSelectedBGColor))
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func updateAvailableBalance(_ amount: Double) {
        self.accountBalance = Float(amount)
        DispatchQueue.main.async {
            self.walletBalanceLabel.text = "$\(String(format: "%.2f", self.accountBalance)) available"
        }
    }
    
    func refreshAccounts() {
        let balance = API().getCurrentWalletBalance()
        self.updateAvailableBalance(balance)
        
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
            vc.title = "Bank Account"
            vc.delegate = self
            vc.selectedAccount = self.bankAccount
        }
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Constants.Theme.mainColor
        doneToolbar.tintColor = .white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(WithdrawFundsTableViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.amountTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.amountTextField.resignFirstResponder()
    }
    
    func setSelectedAccount(account: [String : Any]) {
        self.bankAccount = account
        self.refreshAccounts()
    }
}
