//
//  FundingSourceTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/25/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

protocol SelectedAccountProtocol {
    func setSelectedAccount(account: [String: Any])
}

class FundingSourceTableViewController: UITableViewController {

    var accounts: [[String: Any]] = []
    var selectedAccount: [String: Any]?
    var delegate: SelectedAccountProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getAccounts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func refreshAccounts() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func getAccounts() {
        API().getLinkedAccounts { success in
            if let nodes = currentUser.nodes {
                self.accounts = nodes
                self.refreshAccounts()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SourceCell", for: indexPath)
        let node = self.accounts[indexPath.row]
        
        cell.accessoryType = .none
        
        if let info = node["info"] as? [String: Any], let nodeID = node["_id"] as? String {
            let sourceLabel = cell.viewWithTag(5) as! UILabel
            let nodeName = info["bank_name"] as? String ?? "Example Checking Account"
            let lastFour = info["account_num"] as? String ?? "0000"
            sourceLabel.text = "\(nodeName) ••••\(lastFour)"
            
            if let selection = selectedAccount, let selectedID = selection["_id"] as? String, selectedID == nodeID {
                cell.accessoryType = .checkmark
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = self.accounts[indexPath.row]
        self.selectedAccount = node
        delegate?.setSelectedAccount(account: node)
        tableView.reloadData()
        
        self.navigationController!.popViewController(animated: true)
    }
}
