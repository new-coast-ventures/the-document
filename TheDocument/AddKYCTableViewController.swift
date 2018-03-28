//
//  AddKYCTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 2/14/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

class AddKYCTableViewController: UITableViewController {
    
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var resendButton: UIButton!
    
    var phoneNumber: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addDoneButtonOnKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func resendButtonTapped(_ sender: Any) {
        
        self.verifyButton.isEnabled = false
        self.resendButton.isEnabled = false
        self.resendButton.setTitle("Sending verification text...", for: .normal)
        
        guard let userRef = currentUser.synapseData, let documents = userRef["documents"] as? [[String: Any]], let phones = userRef["phone_numbers"] as? [String], let phoneNumber = phones.first else {
            log.debug("No docs or no permissions or no phone")
            return
        }
        
        var phoneDoc: [String: Any] = [:]
        var mainDoc: [String: Any] = [:]
        documents.forEach { document in
            if let socialDocs = document["social_docs"] as? [[String: Any]] {
                socialDocs.forEach { doc in
                    if let type = doc["document_type"] as? String, type == "PHONE_NUMBER_2FA" {
                        phoneDoc = doc
                        mainDoc = document
                    }
                }
            }
        }
        
        guard let documentId = mainDoc["id"] as? String else { log.debug("Could not find the main document"); return }
        guard let phoneDocumentId = phoneDoc["id"] as? String else { log.debug("Could not find the PHONE_NUMBER_2FA document"); return }
        
        API().resendPhoneKYC(documentId: documentId, phoneNumber: phoneNumber, phoneDocumentId: phoneDocumentId) { success in
            DispatchQueue.main.async {
                self.verifyButton.isEnabled = true
                self.resendButton.isEnabled = true
                if (success) {
                    self.resendButton.setTitle("Verification text sent!", for: .normal)
                } else {
                    self.resendButton.setTitle("Unable to send text. Tap here to try again.", for: .normal)
                }
            }
        }
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        verifyButton.setTitle("Verifying...", for: .normal)
        verifyButton.isEnabled = false
        
        guard let code = textField.text else { showAlert(message: "Please enter the verification code that was sent to your phone"); return }
        
        guard let userRef = currentUser.synapseData, let documents = userRef["documents"] as? [[String: Any]], let phones = userRef["phone_numbers"] as? [String], let phone = phones.first else {
            log.debug("No docs or no permissions or phones")
            return
        }

        var phoneDoc: [String: Any] = [:]
        var mainDoc: [String: Any] = [:]
        documents.forEach { document in
            if let socialDocs = document["social_docs"] as? [[String: Any]] {
                socialDocs.forEach { doc in
                    if let type = doc["document_type"] as? String, type == "PHONE_NUMBER_2FA" {
                        phoneDoc = doc
                        mainDoc = document
                    }
                }
            }
        }
        
        guard let documentId = mainDoc["id"] as? String else { log.debug("Could not find the main document"); return }
        guard let phoneDocumentId = phoneDoc["id"] as? String else { log.debug("Could not find the PHONE_NUMBER_2FA document"); return }
        
        API().updatePhoneKYC(documentId: documentId, phoneNumber: phone, phoneDocumentId: phoneDocumentId, code: code) { success in
            if (success) {
                log.info("Was able to successfully update phone number!")
                self.complete()
            } else {
                log.debug("Unable to update phone KYC")
            }
        }
    }
    
    func complete() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func closeModal(_ sender: Any) {
        DispatchQueue.main.async {
            self.navigationController!.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Constants.Theme.mainColor
        doneToolbar.tintColor = .white
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(AddKYCTableViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.textField.inputAccessoryView = doneToolbar
    }
}

extension AddKYCTableViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
