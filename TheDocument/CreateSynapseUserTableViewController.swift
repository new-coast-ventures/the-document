//
//  CreateSynapseUserTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/28/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

class CreateSynapseUserTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var firstNameLabel: UITextField!
    @IBOutlet weak var lastNameLabel: UITextField!
    @IBOutlet weak var phoneNumberLabel: UITextField!
    @IBOutlet weak var birthdateLabel: UITextField!
    @IBOutlet weak var addressLabel: UITextField!
    @IBOutlet weak var cityLabel: UITextField!
    @IBOutlet weak var stateLabel: UITextField!
    @IBOutlet weak var zipLabel: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    var birthDay: Int?
    var birthMonth: Int?
    var birthYear: Int?
    
    let birthPicker = UIDatePicker()
    let statePicker = UIPickerView()
    
    let stateOptions = ["AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FM", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MH", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VI", "VA", "WA", "WV", "WI", "WY"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        birthPicker.datePickerMode = UIDatePickerMode.date
        birthPicker.addTarget(self, action: #selector(CreateSynapseUserTableViewController.setBirthdate), for: .valueChanged)
        birthdateLabel.inputView = birthPicker
        
        statePicker.delegate = self
        stateLabel.inputView = statePicker
        
        if let userRef = currentUser.synapseData, let documents = userRef["documents"] as? [[String: Any]], let document = documents.first {
            if let phones = userRef["phone_numbers"] as? [String] {
                phoneNumberLabel.text = phones.first
            }
            if let fullName = document["name"] as? String {
                var nameParts = fullName.components(separatedBy: " ")
                if nameParts.count > 1 {
                    let lastName = nameParts.popLast()
                    let firstName = nameParts.joined(separator: " ")
                    firstNameLabel.text = firstName
                    firstNameLabel.isEnabled = false
                    lastNameLabel.text = lastName
                    lastNameLabel.isEnabled = false
                }
            }
            
            if let social_docs = document["social_docs"] as? [[String: Any]] {
                social_docs.forEach({ doc in
                    guard let docType = doc["document_type"] as? String, let status = doc["status"] as? String, status == "SUBMITTED|VALID" else { return }
                    
                    if (docType == "PHONE_NUMBER") {
                        phoneNumberLabel.isEnabled = false
                    }
                })
            }
        }
        
        addDoneButtonOnKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Verify Me"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        self.handleAuthentication()
    }
    
    @IBAction func closeModal(_ sender: Any) {
        DispatchQueue.main.async {
            self.navigationController!.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func setBirthdate() {
        let date = birthPicker.date
        let components = NSCalendar.current.dateComponents([.day,.month,.year],from:date)
        if let day = components.day, let month = components.month, let year = components.year {
            birthDay = day
            birthMonth = month
            birthYear = year
            birthdateLabel.text = "\(month)/\(day)/\(year)"
        }
    }
    
    func handleAuthentication() {
        guard let state = stateLabel.text, ["FL", "IL", "NY"].contains(state) else {
            log.info("handleAuthentication failed guard statement due to state requirements: \(stateLabel.text)")
            showAlert(message: "Due to legal restrictions, only users from Florida, Illinois, and New York can connect a bank account. We are working hard to include additional states and countries. Thank you for understanding.")
            return
        }
        
        guard let firstName = firstNameLabel.text, let lastName = lastNameLabel.text, let phoneNumber = phoneNumberLabel.text, let address = addressLabel.text, let city = cityLabel.text, let zip = zipLabel.text, let _ = birthDay, let _ = birthMonth, let _ = birthYear else {
            showAlert(message: "All fields are required")
            return
        }
        
        self.continueButton.setTitle("VERIFYING...", for: .normal)
        self.continueButton.isEnabled = false
        
        let name = "\(firstName) \(lastName)"
        if let uid = currentUser.synapseUID, uid.isBlank == false {
            // User already exists, add KYC
            API().addKYC(email: currentUser.email, phone: phoneNumber, name: name, birthDay: birthDay!, birthMonth: birthMonth!, birthYear: birthYear!, addressStreet: address, addressCity: city, addressState: state, addressPostalCode: zip) { success in
                if (success) {
                    self.complete()
                } else {
                    self.handleError()
                }
            }
        } else {
            API().createSynapseUser(email: currentUser.email, phone: phoneNumber, name: name, birthDay: birthDay!, birthMonth: birthMonth!, birthYear: birthYear!, addressStreet: address, addressCity: city, addressState: state, addressPostalCode: zip) { success in
                if (success) {
                    API().authorizeSynapseUser({ (status) in
                        self.complete()
                    })
                } else {
                    self.handleError()
                }
            }
        }
    }
    
    func handleError() {
        DispatchQueue.main.async {
            self.continueButton.setTitle("VERIFY & CONTINUE", for: .normal)
            self.continueButton.isEnabled = true
        }
    }
    
    func complete() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "verify_phone_segue", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AddKYCTableViewController {
            vc.phoneNumber = self.phoneNumberLabel.text
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
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(CreateSynapseUserTableViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.firstNameLabel.inputAccessoryView = doneToolbar
        self.lastNameLabel.inputAccessoryView = doneToolbar
        self.phoneNumberLabel.inputAccessoryView = doneToolbar
        self.birthdateLabel.inputAccessoryView = doneToolbar
        self.addressLabel.inputAccessoryView = doneToolbar
        self.cityLabel.inputAccessoryView = doneToolbar
        self.stateLabel.inputAccessoryView = doneToolbar
        self.zipLabel.inputAccessoryView = doneToolbar
    }
}

extension CreateSynapseUserTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stateOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stateOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        stateLabel.text = stateOptions[row]
    }
}
