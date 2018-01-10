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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getWallet()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func withdrawFunds(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    func getWallet() {
        print("Getting wallet...")
        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: String] {
            let amount = balance["amount"] ?? "0.00"
            self.walletBalanceLabel.text = "$\(amount) available"
            
        } else {
            API().getWallet { success in
                if success {
                    print("Got wallet")
                    DispatchQueue.main.async {
                        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: String] {
                            print("WALLET LOADED: \(wallet)")
                            let amount = balance["amount"] ?? "0.00"
                            self.walletBalanceLabel.text = "$\(amount) available"
                        } else {
                            self.walletBalanceLabel.text = "$0.00 available"
                        }
                    }
                } else {
                    print("Error getting wallet")
                }
            }
        }
    }
}
