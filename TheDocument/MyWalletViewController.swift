//
//  MyWalletViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/9/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit
import Firebase

class MyWalletViewController: UIViewController {

    @IBOutlet weak var accountBalanceLabel: UILabel!
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var transactionsTableView: UITableView!
    
    let dateFormatter = DateFormatter()

    var accountBalance: Float = 0.00
    var walletAccount: [String: Any]?
    var transactions: [[String: Any]] = []
    
    var walletBalance: Double = 0.00
    var ledgerBalance: Double = 0.00
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        depositButton.layer.cornerRadius = 3.0
        withdrawButton.layer.cornerRadius = 3.0
        
        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: String] {
            let amount = balance["amount"] ?? "0.00"
            self.accountBalanceLabel.text = "$\(amount)"
        } else {
            self.accountBalanceLabel.text = "---"
        }
        
        // Remove extra seperator lines
        transactionsTableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getWalletAccount()
        
        Database.database().reference(withPath: "ledger/\(currentUser.uid)").observe(.value, with: { (snapshot) in
            // Get user value
            let dict = snapshot.value as? NSDictionary
            let _ = dict?.allKeys
            let fundsHeld = dict?.allValues
            
            var totalHeld = 0
            if let amounts = fundsHeld as? [Int] {
                amounts.forEach({ amount in
                    totalHeld += amount
                })
            }
            
            self.ledgerBalance = Double(totalHeld)
            self.updateAvailableBalance()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getTransactions() {
        guard let wallet = currentUser.wallet, let walletId = wallet["_id"] as? String else { return }
        API().listTransactions(nodeId: walletId) { response in
            self.transactions = response
            DispatchQueue.main.async {
                self.transactionsTableView.reloadData()
            }
        }
    }
    
    func updateAvailableBalance() {
        self.accountBalance = Float(walletBalance - ledgerBalance)
        
        DispatchQueue.main.async {
            if (self.accountBalance <= 0) {
                self.accountBalanceLabel.text = "---"
            } else {
                self.accountBalanceLabel.text = "$\(String(format: "%.2f", self.accountBalance))"
            }
        }
    }
    
    func refreshAccounts() {
        self.getTransactions()
        API().getCurrentWalletBalance { balance in
            self.walletBalance = balance
            self.updateAvailableBalance()
        }
        
        DispatchQueue.main.async {  
            self.transactionsTableView.reloadData()
            
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
    
    @IBAction func depositFunds(_ sender: Any) {
    }
    
    @IBAction func withdrawFunds(_ sender: Any) {
    }
}

extension MyWalletViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let amountLabel = cell.viewWithTag(2) as! UILabel
        let infoLabel = cell.viewWithTag(3) as! UILabel
        let subtextLabel = cell.viewWithTag(4) as! UILabel

        if (indexPath.row < transactions.count) {
            let transaction = transactions[indexPath.row]
            
            var amount = 0.00
            var amountString = ""
            var accountName = ""
            var dateString = "-"
            
            if let amountBlock = transaction["amount"] as? [String: Any], let amt = amountBlock["amount"] as? Double {
                amount = amt
            }
            
            if let fromBlock = transaction["from"] as? [String: Any], let nodeID = fromBlock["id"] as? String, let type = fromBlock["type"] as? String {
                if (type == "ACH-US") {
                    accountName = "Deposit to Wallet"
                    amountString = "$\(String(format: "%.2f", amount))"
                    amountLabel.textColor = UIColor(red: 0/255, green: 84/255, blue: 147/255, alpha: 1.0)
                } else if (nodeID == currentUser.walletID) {
                    accountName = "Challenge Entry Fee"
                    amountString = "-$\(String(format: "%.2f", amount))"
                    amountLabel.textColor = .red
                } else {
                    accountName = "Challenge Payout"
                    amountString = "$\(String(format: "%.2f", amount))"
                    amountLabel.textColor = UIColor(red: 0/255, green: 84/255, blue: 147/255, alpha: 1.0)
                }
            }
            
            if let toBlock = transaction["to"] as? [String: Any], let type = toBlock["type"] as? String {
                if (type == "ACH-US") {
                    accountName = "Withdrawal to Bank"
                    amountString = "-$\(String(format: "%.2f", amount)) - \(accountName)"
                    amountLabel.textColor = .red
                }
            }
            
            if let extraBlock = transaction["extra"] as? [String: Any] {
                if let timestamp = extraBlock["created_on"] as? Double {
                    let epochTime = TimeInterval(timestamp) / 1000
                    let date = Date(timeIntervalSince1970: epochTime)
                    dateString = dateFormatter.string(from: date)
                }
            }
            
            var status = "Pending"
            if let statusBlock = transaction["recent_status"] as? [String: Any], let statusString = statusBlock["status"] as? String {
                if statusString == "CANCELED" {
                    status = "Canceled"
                    amountString = "---"
                    amountLabel.textColor = .lightGray
                } else if statusString == "QUEUED-BY-SYNAPSE" {
                    status = "Pending"
                } else if statusString == "PROCESSING-DEBIT" {
                    status = "Processing"
                } else if statusString == "SETTLED" {
                    status = dateString
                }
            }
            
            amountLabel.text = amountString
            infoLabel.text = accountName
            subtextLabel.text = status
        }
        
        return cell
    }
}
