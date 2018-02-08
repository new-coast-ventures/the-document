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
        oldPasswordTextField.layer.dropShadow()
        newPasswordTextField.layer.dropShadow()
        saveButton.layer.cornerRadius = 3.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField == oldPasswordTextField) {
            newPasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }
}

extension ChangePasswordViewController {
    func updatePassword(_ newPassword: String, _ reauthenticate: Bool = true) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { (error) in
            if error != nil && reauthenticate == true {
                log.error(error!)
                self.reauthenticateUser(newPassword)
            } else if error != nil {
                log.error(error!)
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
                log.error(error!)
                self.showAlert(message: "We're having trouble connecting. Please try again later.")
            } else {
                self.updatePassword(newPassword, false)
            }
        }
    }
}
