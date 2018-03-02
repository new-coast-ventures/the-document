//
//  NewChallengeViewController.swift
//  TheDocument
//

import UIKit
import Firebase
import SearchTextField
import CoreLocation

class NewChallengeViewController: BaseViewController {

    @IBOutlet weak var challengeName:           InputField!
    @IBOutlet weak var challengeFormat:         InputField!
    @IBOutlet weak var challengeLocation:       InputField!
    @IBOutlet weak var challengeTime:           InputField!
    @IBOutlet weak var challengePrice:          InputField!
    @IBOutlet weak var createChallengeButton:   UIButton!
    @IBOutlet weak var walletBalanceButton:     UIButton!
    
    var locationManager: CLLocationManager!
    let approvedStates = ["FL", "Florida", "IL", "Illinois", "NY", "New York"]
    
    var challenge: Challenge!
    var toId:String? = nil
    var groupId:String? = nil
    var dollarLabel: UILabel!
    var toggle: UIBarButtonItem!
    var togglePicker: Bool = false
    var prizeable: Bool = false
    
    var approvedChallenges: [String] = [String]()
    var challengeFormats: [String] = [String]()
    var priceOptions: [Int] = [Int]()
    
    let challengePicker = UIPickerView()
    let amountPicker = UIPickerView()
    let formatPicker = UIPickerView()
    let timePicker = UIDatePicker()
    
    var accountBalance: Float = 0.00
    var walletBalance: Double = 0.00
    var ledgerBalance: Double = 0.00
    var walletAccount: [String: Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load user location
        self.getUserLocation()
        
        // Initially hide the payment-related fields
        self.handlePrizeable()
        
        // Set initial picker values
        priceOptions = [0, 1, 5, 10, 25, 50]
        challengeFormats = ["1-on-1", "2-on-2"]
        approvedChallenges = ["Cornhole", "Ladder Toss", "Washers", "Frisbee Golf", "Ring Toss", "Pop-a-Shot", "Pong",
                              "Flip Cup", "Spinning", "Running", "Circuit Training", "Weight Lifting", "Golf", "Tennis", "Basketball", "Bowling",
                              "Skiing", "Video Game", "Checkers", "Chess", "Backgammon"].sorted()
        
        walletBalanceButton.isHidden = true
        challengePicker.delegate = self
        amountPicker.delegate = self
        formatPicker.delegate = self
        
        // Set up challenge picker
        // challengeName.inputView = challengePicker
        
        // Set up challenge time
        timePicker.minuteInterval = 30
        timePicker.addTarget(self, action: #selector(NewChallengeViewController.setTime), for: .valueChanged)
        challengeTime.inputView = timePicker
        
        // Set up dollar label
        dollarLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        dollarLabel.backgroundColor = .clear
        dollarLabel.numberOfLines = 1
        dollarLabel.textAlignment = .right
        dollarLabel.textColor = .darkText
        dollarLabel.font = UIFont(name: "OpenSans", size: 16)!
        dollarLabel.text = "$"
        
        // Set up price field
        challengePrice.leftViewMode = challengePrice.text == "" ? .never : .always
        challengePrice.leftView = dollarLabel
        challengePrice.isHidden = true
        challengePrice.isEnabled = false
        challengePrice.inputView = amountPicker
        dollarLabel.sizeToFit()
        
        // Set up format field
        challengeFormat.text = "1-on-1"
        challengeFormat.isEnabled = true
        challengeFormat.isHidden = (toId != nil)
        challengeFormat.inputView = formatPicker
        
        // Final setup
        setupChallengeNameKeyboard()
        addDoneButtonOnKeyboard()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideControls)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getWallet()
        self.refreshTransactions()
        
        Database.database().reference(withPath: "ledger/\(currentUser.uid)").observe(.value, with: { (snapshot) in
            // Get user value
            let dict = snapshot.value as? NSDictionary
            let _ = dict?.allKeys
            let fundsHeld = dict?.allValues
            
            var totalHeld = 0
            if let amounts = fundsHeld as? [Int] {
                amounts.forEach({ amount in
                    totalHeld += amount
                })
            }
            
            self.ledgerBalance = Double(totalHeld)
            self.updateAvailableBalance()
        })
    }

    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem? = nil) { dismiss(animated: true, completion: nil) }
    
    @IBAction func createChallengeButtonTapped(_ sender: Any) {
        let formatText = challengeFormat.text ?? "1-on-1"
        guard let newChallenge = Challenge.short(name: challengeName.text, format: formatText, location: challengeLocation.text, time: challengeTime.text) else {
            showAlert(message: Constants.Errors.inputDataChallenge.rawValue)
            return
        }

        challenge = newChallenge
        challenge.fromId = currentUser.uid
        challenge.group = groupId
        
        if let priceString = challengePrice.text, let price = Int(priceString) {
            if accountBalance < Float(price) {
                showAlert(message: "You don't have enough funds to create this challenge. Please add more funds on the Settings page.")
            } else {
                challenge.price = price
                startChallenge()
            }
        } else {
            startChallenge()
        }
    }
    
    func startChallenge() {
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
    
    func updateAvailableBalance() {
        self.accountBalance = Float(walletBalance - ledgerBalance)
        DispatchQueue.main.async {
            if (self.accountBalance < 0) {
                self.walletBalanceButton.isHidden = true
            } else {
                self.walletBalanceButton.setTitle("You have $\(String(format: "%.2f", self.accountBalance)) available", for: .normal)
                self.walletBalanceButton.isHidden = false
            }
        }
    }
    
    func refreshAccounts() {
        API().getCurrentWalletBalance { balance in
            self.walletBalance = balance
            self.updateAvailableBalance()
        }
    }
    
    func refreshTransactions() {
        guard let wallet = currentUser.wallet, let walletId = wallet["_id"] as? String else { return }
        API().listTransactions(nodeId: walletId)
    }
    
    func getWallet() {
        if let wallet = currentUser.wallet, let _ = wallet["_id"] as? String {
            walletAccount = wallet
            self.refreshAccounts()
        } else {
            API().getWallet({ (success) in
                self.walletAccount = currentUser.wallet
                self.refreshAccounts()
            })
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
    
    @objc func hideControls() {
        view.endEditing(true)
    }
    
    @objc func setTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        challengeTime.text = formatter.string(from: timePicker.date)
    }
    
    @objc func doneButtonAction() {
        self.challengeName.resignFirstResponder()
        self.challengeFormat.resignFirstResponder()
        self.challengePrice.resignFirstResponder()
        self.challengeTime.resignFirstResponder()
        self.challengeLocation.resignFirstResponder()
    }
    
    @objc func toggleCustomName() {
        if self.togglePicker {
            toggle.title = "Prize Challenge"
            challengeName.text = nil
            challengeName.inputView = nil
        } else {
            toggle.title = "Custom Challenge"
            challengeName.inputView = self.challengePicker
        }

        challengeName.reloadInputViews()
        self.togglePicker = !self.togglePicker
    }
    
    func setupChallengeNameKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Constants.Theme.mainColor
        doneToolbar.tintColor = .white
        
        toggle = UIBarButtonItem(title: "Prize Challenge", style: .done, target: self, action: #selector(NewChallengeViewController.toggleCustomName))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(NewChallengeViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(toggle)
        items.append(done)
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.challengeName.inputAccessoryView = doneToolbar
        self.challengeFormat.inputAccessoryView = doneToolbar
        self.challengePrice.inputAccessoryView = doneToolbar
        self.challengeTime.inputAccessoryView = doneToolbar
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
        
        self.challengeFormat.inputAccessoryView = doneToolbar
        self.challengePrice.inputAccessoryView = doneToolbar
        self.challengeTime.inputAccessoryView = doneToolbar
        self.challengeLocation.inputAccessoryView = doneToolbar
    }
    
    func handlePrizeable(_ prizeable: Bool = false) {
        self.prizeable = prizeable
        self.challengePrice.isEnabled = prizeable
        self.walletBalanceButton.isHidden = !prizeable
        
        if let name = self.challengeName.text, self.approvedChallenges.contains(name), prizeable == true {
            self.challengePrice.isHidden = false
        } else {
            self.challengePrice.isHidden = true
            self.challengePrice.text = ""
        }
    }
}

extension NewChallengeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case challengePicker:
            return approvedChallenges.count
        case formatPicker:
            return challengeFormats.count
        case amountPicker:
            return priceOptions.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case challengePicker:
            return approvedChallenges[row]
        case formatPicker:
            return challengeFormats[row]
        case amountPicker:
            return "$\(priceOptions[row])"
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == challengePicker {
            challengeName.text = approvedChallenges[row]
        } else if pickerView == formatPicker {
            challengeFormat.text = challengeFormats[row]
        } else if pickerView == amountPicker {
            challengePrice.text = "\(priceOptions[row])"
            challengePrice.leftViewMode = challengePrice.text == "" ? .never : .always
        }
    }
}

extension NewChallengeViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == self.challengeName {
            self.handlePrizeable(self.prizeable)
        }
        return true
    }
}

extension NewChallengeViewController: CLLocationManagerDelegate {
    func getUserLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 10000
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0] as CLLocation
        self.lookUpCurrentLocation { placemark in
            guard let location = placemark, let state = location.administrativeArea else { self.handlePrizeable(false); return }
            
            log.debug("The user's current state is \(state)")
            if self.approvedStates.contains(state) {
                self.handlePrizeable(true)
            } else {
                self.handlePrizeable(false)
            }
        }
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?) -> Void) {
        // Use the last reported location.
        if let lastLocation = self.locationManager.location {
            let geocoder = CLGeocoder()
            
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                                            completionHandler: { (placemarks, error) in
                                                if error == nil {
                                                    let firstLocation = placemarks?[0]
                                                    completionHandler(firstLocation)
                                                }
                                                else {
                                                    // An error occurred during geocoding.
                                                    completionHandler(nil)
                                                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        log.warning(error)
    }
}
