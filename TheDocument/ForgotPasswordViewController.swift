//
//  ForgotPasswordViewController.swift
//  TheDocument
//


import Foundation
import UIKit
import FirebaseAuth
class ForgotPasswordViewController: BaseViewController {
    
    @IBOutlet weak var forgotPasswordEmailTextFieldd: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        forgotPasswordEmailTextFieldd.delegate = self
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resetPasswordButtonTapped(_ sender: UIButton? = nil) {
        guard let email = forgotPasswordEmailTextFieldd.text else {
            self.showAlert(message: Constants.Errors.emailFormat.rawValue)
            return;
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if error != nil {
                log.error(error!)
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
                return
            }
            
            self.showAlert(message: Constants.Messages.resetPasswordSuccess.rawValue)
            self.performSegue(withIdentifier: "goto_login", sender: nil)
        }
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resetPasswordButtonTapped()
        return true
    }
}
