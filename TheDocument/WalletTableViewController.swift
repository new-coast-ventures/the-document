//
//  WalletTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 12/7/17.
//  Copyright © 2017 Refer To The Document. All rights reserved.
//

import UIKit

class WalletTableViewController: BaseTableViewController {
    
    var nodes: [[String: Any]] = [[:]]

    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = currentUser.nodes {
            nodes = currentUser.nodes!
        }
        
        self.refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func rowsCount() -> Int {
        return 1
    }
    
    override func emptyViewAction() {
        self.performSegue(withIdentifier: "sp_create_user", sender: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return nodes.count + 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Current Balance"
        case 1:
            return "Accounts"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        cell.acceptButton.isHidden = true
        cell.loader.isHidden = true
        
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            return setupBalanceCell(cell: cell)
        case (1, _):
            return setupNodeCell(cell: cell, indexPath: indexPath)
        default:
            return cell
        }
    }
    
    func setupBalanceCell(cell: ItemTableViewCell) -> ItemTableViewCell {
        var balance = "0.00"
        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balanceJson = info["balance"] as? [String: String] {
            balance = balanceJson["amount"] ?? "0.00"
        }
        cell.itemImageView.image = UIImage()
        cell.topLabel.text = "$\(balance)"
        cell.bottomLabel.text = "Amount available for challenge entry fees"
        return cell
    }
    
    func setupNodeCell(cell: ItemTableViewCell, indexPath: IndexPath) ->ItemTableViewCell {
        if let indexPath.row < nodes.count {
            let node = nodes[indexPath.row]
            let name = node.key
            
            if let info = nodeJson["info"] as? [String: Any] {
                let nodeName = info["bank_name"] as? String ?? "Example Checking Account"
                let lastFour = info["account_num"] as? String ?? "0000"
                cell.topLabel.text = "\(nodeName)"
                cell.bottomLabel.text = "•••• •••• •••• \(lastFour)"
            }
            
        } else {
            cell.itemImageView.image = UIImage()
            cell.topLabel.text = "Link Bank Account..."
            cell.bottomLabel.text = ""
        }
        
        
        
        cell.itemImageView.isHidden = true
        return cell
    }
    
    func getNodes() {
    }
}
