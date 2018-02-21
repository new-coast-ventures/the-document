//
//  MFAViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/25/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class MFAViewController: UIViewController, UITextFieldDelegate {
    
    var step = 0
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subheaderLabel: UILabel!
    @IBOutlet weak var legalLabel: UILabel!
    @IBOutlet weak var pinTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDoneButtonOnKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func hideText() {
        self.headerLabel.isHidden = true
        self.subheaderLabel.isHidden = true
        self.legalLabel.isHidden = true
    }
    
    func showText() {
        self.headerLabel.isHidden = false
        self.subheaderLabel.isHidden = false
        self.legalLabel.isHidden = false
    }
    
    func nextStep(headerText: String, subheaderText: String, legalText: String, buttonText: String) {
        step += 1
        DispatchQueue.main.async {
            self.headerLabel.text = headerText
            self.subheaderLabel.text = subheaderText
            self.legalLabel.text = legalText
            self.pinTextField.isHidden = false
            self.verifyButton.setTitle(buttonText, for: .normal)
            self.verifyButton.isEnabled = true
            self.showText()
        }
    }
    
    func showError(_ msg: String) {
        DispatchQueue.main.async {
            self.showAlert(message: msg)
        }
    }
    
    @IBAction func verifyDevice(_ sender: Any) {
        if step == 0 {
            hideText()
            verifyButton.setTitle("Sending...", for: .normal)
            verifyButton.isEnabled = false
            API().requestMFA { (success) in
                if (success) {
                    self.nextStep(headerText: "Your code was sent", subheaderText: "When you receive the code, enter it below and tap 'Submit PIN' to verify this device.", legalText: "", buttonText: "Submit PIN")
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Unable to send verification code. Please contact us at support@refertothedocument.com")
                    }
                }
            }
        } else if step == 1 {
            guard let pinText = self.pinTextField.text else { self.showError("Please enter a PIN and resubmit"); return }
            verifyButton.setTitle("Verifying...", for: .normal)
            verifyButton.isEnabled = false
            API().verifyMFA(pin: pinText) { (success) in
                guard success else { self.completeMFA(); return }
                self.completeMFA()
            }
        }
    }
    
    func completeMFA() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func doneButtonAction() {
        self.pinTextField.resignFirstResponder()
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Constants.Theme.mainColor
        doneToolbar.tintColor = .white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(MFAViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.pinTextField.inputAccessoryView = doneToolbar
    }
}
