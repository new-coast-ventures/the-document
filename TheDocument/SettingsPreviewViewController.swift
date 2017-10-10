//
//  SettingsPreviewViewController.swift
//  TheDocument
//

import UIKit
import FirebaseAuth

var webview: UIWebView!
var loadingIcon: UIActivityIndicatorView?
var selectedIndexPath: IndexPath?

let settingsBaseURL = "https://the-document-prod.herokuapp.com/"

class SettingsPreviewViewController: BaseTableViewController {
    
    @IBOutlet weak var depositButton: UIButton!
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        depositButton.layer.cornerRadius = 3.0
        photoImageView.layer.cornerRadius = photoImageView.frame.width/2
        
        if let imageData = downloadedImages["\(currentUser.uid)"] {
            setPhotoWithData(imageData: imageData)
        } else {
            appDelegate.downloadImageFor(id: "\(currentUser.uid)", section: "photos"){[weak self] success in
                guard success, let sSelf = self,  let imageData = downloadedImages["\(currentUser.uid)"]  else { return }
                sSelf.setPhotoWithData(imageData: imageData)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        case (1, 1):
            resetPasswordAction()
        case (1, _): break
            // do nothing
        case (4, 0):
            currentUser.logout()
        default:
            performSegue(withIdentifier: "open_webview", sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return currentUser.name
        case 1:
            return "Account"
        case 2:
            return "Support"
        case 3:
            return "About"
        default:
            return nil
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
                    print(error.debugDescription)
                    self.showAlert(message: Constants.Errors.defaultError.rawValue)
                    return
                }
                
                self.showAlert(message: Constants.Messages.resetPasswordSuccess.rawValue)
            }
        } )
        
        self.present(alert, animated: true, completion: nil)
    }
}
