//
//  AccountsTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 12/7/17.
//  Copyright © 2017 Refer To The Document. All rights reserved.
//

import UIKit

class AccountsTableViewController: BaseTableViewController {
    
    var nodes: [[String: Any]]?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = currentUser.nodes {
            nodes = currentUser.nodes!
            self.refresh()
        }
        
        getNodes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func rowsCount() -> Int {
        return nodes?.count ?? 1
    }
    
    override func emptyViewAction() {
        self.performSegue(withIdentifier: "sp_create_user", sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return nodes?.count ?? 0
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let nodeCount = nodes?.count ?? 0
        if (section == 0 && nodeCount > 0) {
            return "Bank Accounts"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        cell.acceptButton.isHidden = true
        cell.itemImageView.image = #imageLiteral(resourceName: "bank_placeholder")
        cell.loader.isHidden = true
        
        if indexPath.section == 1 {
            cell.topLabel.text = "Add new bank account"
            cell.bottomLabel.text = "Click to connect a funding source"
            cell.tag = 1
            cell.accessoryType = .disclosureIndicator
            
        } else if let nodes = nodes, nodes.count > 0 {
            if let info = nodes[indexPath.row]["info"] as? [String: Any] {
                let nodeName = info["bank_name"] as? String ?? "Example Checking Account"
                let lastFour = info["account_num"] as? String ?? "0000"
                if let logoUrl = info["bank_logo"] as? String, let url = URL(string: logoUrl) {
                    cell.itemImageView.imageFromServerURL(url) { /* do nothing */ }
                }
                
                cell.topLabel.text = "\(nodeName)"
                cell.bottomLabel.text = "•••• •••• •••• \(lastFour)"
                cell.tag = 0
                cell.accessoryType = .none
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 1) {
            performSegue(withIdentifier: "selectBankSegue", sender: self)
        }
    }
    
    func getNodes() {        
        API().getLinkedAccounts { success in
            if success {
                DispatchQueue.main.async {
                    self.nodes = currentUser.nodes!
                    self.tableView.reloadData()
                    self.refresh()
                }
            } else {
                log.warning("Error getting linked accounts")
            }
        }
    }
}
