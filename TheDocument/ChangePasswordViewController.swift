//
//  ChangePasswordViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/4/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit
import Firebase

class ChangePasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func savePassword(_ sender: Any) {
        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty else {
            showAlert(message: "New password can't be blank")
            return
        }

        updatePassword(newPassword)
    }
}

extension ChangePasswordViewController {
    func updatePassword(_ newPassword: String, _ reauthenticate: Bool = true) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { (error) in
            if error != nil && reauthenticate == true {
                self.reauthenticateUser(newPassword)
            } else if error != nil {
                self.showAlert(message: "Something went wrong. Please try again later.")
            } else {
                self.showAlert(title: "Success!", message: "Your password has been successfully updated", closure: { action in
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    func reauthenticateUser(_ newPassword: String) {
        guard let oldPassword = oldPasswordTextField.text else {
            showAlert(message: "Something went wrong. Please try again later.")
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email, password: oldPassword)
        Auth.auth().currentUser?.reauthenticate(with: credential) { error in
            if error != nil {
                self.showAlert(message: "We're having trouble connecting. Please try again later.")
            } else {
                self.updatePassword(newPassword, false)
            }
        }
    }
}
