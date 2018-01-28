//
//  DepositFundsTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/9/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class DepositFundsTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var bankLabel: UILabel!
    @IBOutlet weak var customAmountTextField: UITextField!
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var customDollarLabel: UILabel!
    
    let tapToHideGesture = UITapGestureRecognizer(target: self, action: #selector(hideControls))
    let presetAmounts = [10, 25, 50, 100]
    
    var bankAccount: [String: Any]?
    var walletAccount: [String: Any]?
    var depositAmount: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        depositButton.setTitle("DEPOSIT $\(depositAmount ?? 0)", for: .normal)
        addDoneButtonOnKeyboard()
        getBankAccount()
        getWalletAccount()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }

        if indexPath.row < presetAmounts.count {
            uncheckCells()
            depositAmount = presetAmounts[indexPath.row]
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .checkmark
                depositButton.setTitle("DEPOSIT $\(depositAmount ?? 0)", for: .normal)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FundingSourceTableViewController {
            vc.source = self.bankLabel.text
        }
    }
    
    @objc func hideControls() {
        self.view.endEditing(true)
    }
    
    @IBAction func depositFunds(_ sender: Any) {
        
        guard let amount = depositAmount else {
            showAlert(message: "Please select an amount")
            return
        }
        
        guard amount >= 5 else {
            showAlert(message: "The minimum deposit amount is $5.")
            return
        }
        
        guard amount <= 100 else {
            showAlert(message: "The maximum deposit amount is currently $100.")
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
        
        API().depositFunds(from: bankId, to: walletId, amount: amount) {
            if ($0) {
                DispatchQueue.main.async {
                    self.showAlert(title: "Deposit Initiated", message: "Bank transfers initiated before 7 PM ET on business days will typically be available the next business day, but it can take up to 3 business days. Business days are Monday to Friday, excluding bank holidays.", closure: { action in
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        if let amount = Int(newString) {
            customDollarLabel.isHidden = false
            depositAmount = amount
        } else {
            customDollarLabel.isHidden = true
        }
        depositButton.setTitle("DEPOSIT $\(depositAmount ?? 0)", for: .normal)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        depositAmount = 0
        checkCell(at: IndexPath(row: 4, section: 1))
        view.addGestureRecognizer(tapToHideGesture)
        depositButton.setTitle("DEPOSIT $\(depositAmount ?? 0)", for: .normal)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        view.removeGestureRecognizer(tapToHideGesture)
        if let amountString = textField.text, let amount = Int(amountString) {
            depositAmount = amount
        }
    }
    
    func uncheckCells() {
        tableView.visibleCells.forEach { cell in
            cell.accessoryType = .none
        }
    }
    
    func checkCell(at indexPath: IndexPath) {
        uncheckCells()
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
    }
    
    func refreshAccounts() {
        
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
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Constants.Theme.mainColor
        doneToolbar.tintColor = .white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(DepositFundsTableViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.customAmountTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.customAmountTextField.resignFirstResponder()
    }
}
