//
//  SettingsPreviewViewController.swift
//  TheDocument
//

import UIKit
import FirebaseAuth
import FirebaseStorageUI

var webview: UIWebView!
var loadingIcon: UIActivityIndicatorView?
var selectedIndexPath: IndexPath?

let settingsBaseURL = "https://the-document-prod.herokuapp.com/"

class SettingsPreviewViewController: BaseTableViewController {
    
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        depositButton.layer.cornerRadius = 3.0
        photoImageView.layer.cornerRadius = photoImageView.frame.width/2
        userNameLabel.text = currentUser.name
        
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        
        // Create a storage reference from our storage service
        let photoRef = storage.reference(forURL: "gs://the-document.appspot.com/photos/\(currentUser.uid)")
        
        self.photoImageView.sd_setImage(with: photoRef, placeholderImage: UIImage(named: "logo-mark-square"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = "Settings"
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if ((identifier == "deposit_segue" || identifier == "wallet_segue" || identifier == "showAccounts" || identifier == "withdraw_segue") && !appDelegate.isSynapseUserVerified()) {
            return false
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Remove "Settings" from back button
        self.navigationItem.title = ""
        
        if segue.identifier == "edit_settings" {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
        
        } else if segue.identifier == "open_webview" {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
            if let webVC = segue.destination as? TDWebViewController, let url = URL(string: selectedURL()) {
                webVC.url = url
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        switch (indexPath.section, indexPath.row) {
        case (0, _): break
            // do nothing
        case (1, _): break
            // do nothing
        case (4, 0):
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "loginViewController") as? LoginViewController {
                currentUser.logout()
                UIApplication.shared.keyWindow?.rootViewController = viewController
                viewController.showLogin()
            }
        default:
            performSegue(withIdentifier: "open_webview", sender: nil)
        }
    }
}

extension SettingsPreviewViewController {
    
    func setPhotoWithData(imageData:Data) {
        DispatchQueue.main.async {
            self.photoImageView.image = UIImage(data: imageData)
        }
    }
    
    func selectedURL() -> String {
        guard let indexPath = selectedIndexPath else { return settingsBaseURL }
        
        switch (indexPath.section, indexPath.row) {
        case (2, 0):
            return settingsBaseURL.appending("faq")
        case (2, 1):
            return settingsBaseURL.appending("feedback")
        case (3, 0):
            return settingsBaseURL.appending("privacy")
        case (3, 1):
            return settingsBaseURL.appending("terms")
        default:
            return settingsBaseURL
        }
    }
    
    func resetPasswordAction() {
        let alert = UIAlertController(title: Constants.resetPasswordTitle, message: Constants.resetAlertConfirmBody, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) )
        alert.addAction(UIAlertAction(title: Constants.resetButtonTitle, style: UIAlertActionStyle.default){ _ in
            Auth.auth().sendPasswordReset(withEmail: currentUser.email) { (error) in
                if error != nil {
                    log.error(error)
                    self.showAlert(message: Constants.Errors.defaultError.rawValue)
                    return
                }
                
                self.showAlert(message: Constants.Messages.resetPasswordSuccess.rawValue)
            }
        } )
        
        self.present(alert, animated: true, completion: nil)
    }
}
