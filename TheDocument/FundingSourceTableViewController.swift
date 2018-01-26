//
//  FundingSourceTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/25/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class FundingSourceTableViewController: UITableViewController {

    var source: String?
    @IBOutlet weak var sourceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourceLabel.text = source ?? "---"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
