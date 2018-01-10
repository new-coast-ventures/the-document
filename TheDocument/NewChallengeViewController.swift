//
//  NewChallengeViewController.swift
//  TheDocument
//

import UIKit
import Firebase
import SearchTextField
import CoreLocation

class NewChallengeViewController: BaseViewController {

    @IBOutlet weak var challengeName:           SearchTextField!
    @IBOutlet weak var challengeFormat:         InputField!
    @IBOutlet weak var challengeLocation:       InputField!
    @IBOutlet weak var challengeTime:           InputField!
    @IBOutlet weak var challengePrice:          InputField!
    @IBOutlet weak var formatPicker:            UIPickerView!
    @IBOutlet weak var timePicker:              UIDatePicker!
    @IBOutlet weak var createChallengeButton:   UIButton!
    @IBOutlet weak var walletBalanceLabel:      UILabel!
    
    let locationManager = CLLocationManager()
    
    var challenge:Challenge!
    var toId:String? = nil
    var groupId:String? = nil
    var approvedChallenges: [String] = [String]()
    var challengeFormats: [String] = [String]()
    var dollarLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletBalanceLabel.isHidden = true
        getWallet()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideControls)))
        
        self.addDoneButtonOnKeyboard()
        
        dollarLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        dollarLabel.backgroundColor = .clear
        dollarLabel.numberOfLines = 1
        dollarLabel.textAlignment = .right
        dollarLabel.textColor = .darkText
        dollarLabel.font = UIFont(name: "OpenSans", size: 16)!
        dollarLabel.text = "$"
        
        challengePrice.addTarget(self, action: #selector(NewChallengeViewController.toggleDollarLabel(sender:)), for: .editingChanged)
        challengePrice.leftViewMode = challengePrice.text == "" ? .never : .always
        challengePrice.leftView = dollarLabel
        challengePrice.isHidden = false
        challengePrice.isEnabled = false
        dollarLabel.sizeToFit()
        
        timePicker.minuteInterval = 30
        timePicker.addTarget(self, action: #selector(NewChallengeViewController.setTime), for: .valueChanged)
        
        challengeFormat.text = "1-on-1"
        challengeFormats = ["1-on-1", "2-on-2"]
        if toId != nil {
            challengeFormat.isHidden = true
        } else {
            challengeFormat.isHidden = false
        }

        approvedChallenges = ["Cornhole", "Ladder Toss", "Washers", "Frisbee Golf", "Ring Toss", "Pop-a-Shot", "Pong", 
        "Flip Cup", "Spinning", "Running", "Circuit Training", "Weight Lifting", "Golf", "Tennis", "Basketball", "Bowling", 
        "Skiing", "Video Game", "Checkers", "Chess", "Backgammon"].sorted()
        
        challengeName.theme.font = UIFont(name: "OpenSans", size: 14)!
        challengeName.highlightAttributes = [NSAttributedStringKey(rawValue: NSAttributedStringKey.font.rawValue):UIFont(name: "OpenSans-Bold", size: 14)!]
        challengeName.theme.bgColor = .white
        challengeName.filterStrings(approvedChallenges)
        challengeName.itemSelectionHandler = { filteredResults, itemPosition in
            let item = filteredResults[itemPosition]
            self.challengePrice.isEnabled = true
            self.challengeName.text = item.title
        }
    }

    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem? = nil) { dismiss(animated: true, completion: nil) }
    
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
        guard let newChallenge = Challenge.short(name: challengeName.text, format: challengeFormat.text, location: challengeLocation.text, time: challengeTime.text) else {
            showAlert(message: Constants.Errors.inputDataChallenge.rawValue)
            return
        }
        
        challenge = newChallenge
        challenge.fromId = currentUser.uid
        challenge.group = groupId
        
        if let priceString = challengePrice.text, let price = Int(priceString) {
            challenge.price = price
        }
        
        if let challengeToId = toId {
            challenge.toId = challengeToId
            challenge.fromId = currentUser.uid
            self.startActivityIndicator()

            API().challengeFriends(challenge: challenge, friendsIds: [challenge.toId]) {
                self.loadChallengeDetailsView(challenge: self.challenge)
            }
        } else {
            performSegue(withIdentifier: Constants.inviteFriendsNewChallengeStoryboardIdentifier, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.inviteFriendsNewChallengeStoryboardIdentifier,
            let destVC = segue.destination as? InviteFriendsTableViewController {
            
            if challenge.format == "1-on-1" {
                destVC.mode = .challenge(challenge)
            } else {
                destVC.mode = .teamChallenge(challenge)
            }
        }
    }
    
    func getWallet() {
        print("Getting wallet...")
        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: String] {
            let amount = balance["amount"] ?? "0.00"
            self.walletBalanceLabel.text = "You have $\(amount) available"
            
        } else {
            API().getWallet { success in
                if success {
                    print("Got wallet")
                    DispatchQueue.main.async {
                        if let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: String] {
                            print("WALLET LOADED: \(wallet)")
                            let amount = balance["amount"] ?? "0.00"
                            self.walletBalanceLabel.text = "You have $\(amount) available"
                        } else {
                            self.walletBalanceLabel.text = "You have $0.00 available"
                        }
                        self.walletBalanceLabel.isHidden = false
                    }
                } else {
                    print("Error getting wallet")
                }
            }
        }
    }
    
    func loadChallengeDetailsView(challenge: Challenge) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
        self.dismiss(animated: false) {
            guard let challengeDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "challengeDetailsViewController") as? ChallengeDetailsViewController, let homeViewController = homeVC, homeViewController.containerViewController.childViewControllers.count > 0 else { return }
            
            homeViewController.showOverviewTapped()
            challengeDetailsViewController.challenge = challenge
            if let navController = homeViewController.containerViewController.childViewControllers[0] as? UINavigationController {
                navController.pushViewController(challengeDetailsViewController, animated: false)
                NCVAlertView().showSuccess("Challenge Created!", subTitle: "")
            }
        }
    }
    
    //MARK: IBActions
    
    @IBAction func timeButtonTapped(_ sender: Any) {
        view.endEditing(true)
        timePicker.isHidden = false
    }
    
    //MARK: Helpers
    
    @objc func hideControls() {
        formatPicker.isHidden = true
        timePicker.isHidden = true
        view.endEditing(true)
    }
    
    @objc func setTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        challengeTime.text = formatter.string(from: timePicker.date)
    }
    
    @objc func doneButtonAction() {
        self.challengePrice.resignFirstResponder()
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
        
        self.challengePrice.inputAccessoryView = doneToolbar
    }
    
    @objc func toggleDollarLabel(sender: UITextField) {
        sender.leftViewMode = sender.text == "" ? .never : .always
    }
}

// Location Management
extension NewChallengeViewController: CLLocationManagerDelegate {
    
    func enableBasicLocationServices() {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            //disableMyLocationBasedFeatures()
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Enable location features
            //enableMyWhenInUseFeatures()
            break
        }
    }
}

extension NewChallengeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return challengeFormats.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return challengeFormats[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.challengeFormat.text = challengeFormats[row]
    }
}

extension SearchTextField {
    override open func awakeFromNib() {
        super.awakeFromNib()
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: self.frame.height - 1, width: self.frame.width, height: 1.0)
        bottomLine.backgroundColor = Constants.Theme.grayColor.cgColor
        self.borderStyle = .none
        self.layer.addSublayer(bottomLine)
    }
}

extension NewChallengeViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        timePicker.isHidden = true
        formatPicker.isHidden = true
        if textField == challengeTime {
            view.endEditing(true)
            timePicker.isHidden = false
            return false
        } else if textField == challengeFormat {
            view.endEditing(true)
            formatPicker.isHidden = false
            return false
        } else if textField == challengePrice {
            textField.keyboardType = .decimalPad
        } else {
            textField.keyboardType = .default
        }
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == self.challengeName, let name = textField.text {
            if approvedChallenges.contains(name) {
                self.challengePrice.isEnabled = true
            } else {
                self.challengePrice.isEnabled = false
                self.challengePrice.text = nil
            }
        }
        return true
    }
}
