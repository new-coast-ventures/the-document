//
//  CreateAccountTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 6/30/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit

class CreateAccountTableViewController: UITableViewController {

    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var legalSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailTextField.text = currentUser.email
        self.displayNameTextField.text = currentUser.name
        self.mobileTextField.text = currentUser.phone
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
    }
    
    deinit {
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 4
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ((indexPath.section, indexPath.row) == (3, 0)) {
            print("Create Synapse User")
            API().createSynapseUser(email: emailTextField.text!, phone: mobileTextField.text!, name: displayNameTextField.text!, { success in
                if (success) {
                    print("Created synapse user")
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "add_kyc", sender: self)
                    }
                } else {
                    print("Something fucked up")
                }
            })
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
