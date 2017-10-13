//
//  LoginViewController.swift
//  TheDocument
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    enum LoginState {
        case login,signup
    }

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    @IBOutlet weak var loginButton: AuthButton!
    @IBOutlet weak var signupButton: AuthButton!
    
    @IBOutlet weak var overlayView: UIView!
    fileprivate var state:LoginState = .login {
        didSet {
            loginButton.isSelected = state == .login ? true : false
            signupButton.isSelected = state == .signup ? true : false
            nameTextField.isHidden =  state == .login ? true : false
            phoneTextField.isHidden =  state == .login ? true : false
            forgotPasswordButton.isHidden = state == .login ? false : true
        }
    }
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.isSelected = true
        signupButton.isSelected = false
        containerView.layer.dropShadow()
        
        view.backgroundColor = Constants.Theme.mainColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopActivityIndicator()
    }
    
    deinit {
        view.gestureRecognizers?.removeAll()
    }
    
    //MARK: IBAction
    
    @IBAction func loginTapped(_ sender: UIButton? = nil) {
        view.endEditing(true)
        guard case .login = state else {
            state = .login
            return
        }
        
        guard let email = emailTextField.text, let password = passwordTextField.text, !email.isEmpty, !password.isEmpty else {
           showAlert(message: Constants.Errors.inputDataLogin.rawValue)
            return
        }
        
        self.startActivityIndicator()
        
        Auth.auth().signIn(withEmail: email,password: password) { (user,error) in
            
            if error != nil {
                self.stopActivityIndicator()
                self.showAlert(message: error?.localizedDescription ?? Constants.Errors.defaultError.rawValue)
            }
        }
    }
    
    @IBAction func signupTapped(_ sender: UIButton? = nil) {
        view.endEditing(true)
        guard case .signup = state else {
            state = .signup
            return
        }

        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text, let phone = phoneTextField.text
            else { return }
        
        var errorMessage = ""
        errorMessage += email.isEmpty ? "\(Constants.Errors.inputDataRegisterEmail.rawValue)\n" : ""
        errorMessage += name.isEmpty ? "\(Constants.Errors.inputDataRegisterName.rawValue)\n"  : ""
        errorMessage += !password.isValidPassword ? "\(Constants.Errors.passwordRequirements.rawValue)\n"  : ""
        
        if !errorMessage.isEmpty {
            showAlert(title: "\(Constants.Errors.inputDataRegister.rawValue)\n", message: errorMessage)
            return
        }
        
        self.startActivityIndicator()
        
        return createUser(email: email, password: password, name: name, phone: phone)
    }

    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        view.endEditing(true)
        let alert = UIAlertController(title: Constants.resetPasswordTitle, message: Constants.resetAlertBody, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = Constants.addFriendAlertPlaceholder
            textField.keyboardType = .emailAddress
        }
        
        alert.addAction(UIAlertAction(title: Constants.resetButtonTitle, style: .default, handler: { [weak alert] (_) in
                guard let email = alert?.textFields?[0].text , !email.isEmpty else { return }
            
                guard email.isEmail else {
                    self.showAlert(message: Constants.Errors.emailFormat.rawValue)
                    return;
                }
                
                Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                    if error != nil {
                        print(error.debugDescription)
                        self.showAlert(message: Constants.Errors.defaultError.rawValue)
                        return
                    }
                    
                    self.showAlert(message: Constants.Messages.resetPasswordSuccess.rawValue)
                }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        
        self.present(alert, animated: true, completion: nil)
    }
    //MARK: Helpers 
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    //MARK : Removes the blinking effect when login in progress
    func hideLogin() {
        self.startActivityIndicator()
    }
    func showLogin() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5,delay: 0 ,options: UIViewAnimationOptions.curveEaseIn,animations: { () -> Void in
                self.overlayView.alpha = 0
            }, completion: nil)
        }
       
    }
}

//MARK: Firebase
extension LoginViewController {
    
    fileprivate func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email,password: password) { (user, error) in
            self.stopActivityIndicator()
            
            if error != nil {
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
            }
        }
    }
    
    fileprivate func createUser(email: String, password: String, name: String, phone: String) {
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            
            guard error == nil else {
                self.stopActivityIndicator()
                print("\(error?.localizedDescription ?? "error creating user")")
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
                return
            }
            
            if let createdUser = user, error == nil {
                var user = [String:String]()
                user["name"] = name
                user["phone"] = phone
                user["email"] = email
                Database.database().reference(withPath: "users/\(createdUser.uid)").setValue(user) { error, ref in
                    guard error == nil else {
                        self.showAlert(message: Constants.Errors.defaultError.rawValue)
                        print("Adding additional info for the user failed with: \(error?.localizedDescription ?? "")" )
                        return
                    }
                    Database.database().reference(withPath: "emails/\(createdUser.uid)").setValue(createdUser.email)
                }
            }
            
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        switch textField {
            case nameTextField:
                phoneTextField.becomeFirstResponder()
            case phoneTextField:
                emailTextField.becomeFirstResponder()
            case emailTextField:
                passwordTextField.becomeFirstResponder()
            case passwordTextField:
                if state == .login{
                    loginTapped()
                } else {
                    signupTapped()
                }
            default: break
        }
        
        
        
        
        return true
    }
}
