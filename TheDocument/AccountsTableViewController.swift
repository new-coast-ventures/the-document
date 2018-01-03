//
//  AccountsTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 12/7/17.
//  Copyright © 2017 Refer To The Document. All rights reserved.
//

import UIKit

class AccountsTableViewController: BaseTableViewController {
    
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
    
//    override func emptyViewAction() {
//        self.performSegue(withIdentifier: "sp_create_user", sender: self)
//    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Bank Account"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        
        //cell.itemImageView.isHidden = true
        cell.acceptButton.isHidden = true
        cell.loader.isHidden = true
        
        let node = nodes[indexPath.row]
        if let info = node["info"] as? [String: Any] {
            let nodeName = info["bank_name"] as? String ?? "Example Checking Account"
            let lastFour = info["account_num"] as? String ?? "0000"
            cell.topLabel.text = "\(nodeName)"
            cell.bottomLabel.text = "•••• •••• •••• \(lastFour)"
        } else {
            cell.itemImageView.image = #imageLiteral(resourceName: "bank_placeholder")
            cell.topLabel.text = "Chase Bank"
            cell.bottomLabel.text = "•••• •••• •••• 5815"
        }
        
        return cell
    }
    
    func getNodes() {
    }
}
