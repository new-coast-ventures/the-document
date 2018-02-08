//
//  MyWalletViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/9/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class MyWalletViewController: UIViewController {

    @IBOutlet weak var accountBalanceLabel: UILabel!
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var withdrawButton: UIButton!
    @IBOutlet weak var transactionsTableView: UITableView!
    
    let dateFormatter = DateFormatter()

    var accountBalance: Float = 0.00
    var walletAccount: [String: Any]?
    var transactions: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateStyle = .long
        //dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" //Specify your format that you want
        
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

        getWalletAccount()
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
    
    func updateAvailableBalance(_ amount: Double) {
        self.accountBalance = Float(amount)
        DispatchQueue.main.async {
            self.accountBalanceLabel.text = "$\(String(format: "%.2f", self.accountBalance))"
        }
    }
    
    func refreshAccounts() {
        let balance = API().getCurrentWalletBalance()
        self.updateAvailableBalance(balance)
        self.getTransactions()
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

        let imageView     = cell.viewWithTag(2) as! UIImageView
        let headlineLabel = cell.viewWithTag(3) as! UILabel
        let subtextLabel  = cell.viewWithTag(4) as! UILabel
        let dateLabel     = cell.viewWithTag(5) as! UILabel
        let statusLabel   = cell.viewWithTag(6) as! UILabel

        if (indexPath.row < transactions.count) {
            let transaction = transactions[indexPath.row]
            var headline = "Deposit to Wallet"
            var status = "Pending"
            var amount = 0.00
            var accountName = ""
            var dateString = "-"
            var image = #imageLiteral(resourceName: "PendingIcon")
            
            if let amountBlock = transaction["amount"] as? [String: Any], let amt = amountBlock["amount"] as? Double {
                amount = amt
            }
            
            if let fromBlock = transaction["from"] as? [String: Any], let nickname = fromBlock["nickname"] as? String {
                accountName = nickname
            }
            
            if let extraBlock = transaction["extra"] as? [String: Any] {
                if let timestamp = extraBlock["created_on"] as? Double {
                    let epochTime = TimeInterval(timestamp) / 1000
                    let date = Date(timeIntervalSince1970: epochTime)
                    dateString = dateFormatter.string(from: date)
                }
                
                if let note = extraBlock["note"] as? String {
                    if note == "Deposit funds from bank to wallet" {
                        headline = "Deposit to Wallet"
                    } else {
                        headline = note
                    }
                }
            }
            
            if let statusBlock = transaction["recent_status"] as? [String: Any], let statusString = statusBlock["status"] as? String {
                if statusString == "CANCELED" {
                    status = "Canceled"
                    image = #imageLiteral(resourceName: "ErrorIcon")
                } else if statusString == "QUEUED-BY-SYNAPSE" {
                    status = "Pending"
                } else if statusString == "PROCESSING-DEBIT" {
                    status = "Processing"
                } else if statusString == "SETTLED" {
                    status = "Complete"
                    image = #imageLiteral(resourceName: "SuccessIcon")
                }
            }
            
            headlineLabel.text = headline
            subtextLabel.text = "$\(String(format: "%.2f", amount)) - \(accountName)"
            dateLabel.text = dateString
            statusLabel.text = status
            imageView.image = image
        }
        
        return cell
    }
}
