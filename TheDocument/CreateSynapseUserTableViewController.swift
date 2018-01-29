//
//  CreateSynapseUserTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/28/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit

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
    
    let stateOptions = ["IL", "NY"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        birthPicker.datePickerMode = UIDatePickerMode.date
        birthPicker.addTarget(self, action: #selector(CreateSynapseUserTableViewController.setBirthdate), for: .valueChanged)
        birthdateLabel.inputView = birthPicker
        
        statePicker.delegate = self
        stateLabel.inputView = statePicker
        
        addDoneButtonOnKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        guard let firstName = firstNameLabel.text, let lastName = lastNameLabel.text, let phoneNumber = phoneNumberLabel.text, let address = addressLabel.text, let city = cityLabel.text, let zip = zipLabel.text, let _ = birthDay, let _ = birthMonth, let _ = birthYear, let state = stateLabel.text else {
            showAlert(message: "All fields are required")
            return
        }
        
        let name = "\(firstName) \(lastName)"
        
        API().createSynapseUser(email: currentUser.email, phone: phoneNumber, name: name, birthDay: birthDay!, birthMonth: birthMonth!, birthYear: birthYear!, addressStreet: address, addressCity: city, addressState: state, addressPostalCode: zip) { success in
            
            if (success) {
                API().authorizeSynapseUser({ (status) in
                    self.complete()
                })
            } else {
                self.complete()
            }
        }
    }
    
    @IBAction func closeModal(_ sender: Any) {
        self.complete()
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
    
    func complete() {
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
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(NewChallengeViewController.doneButtonAction))
        
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
