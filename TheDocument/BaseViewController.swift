//
//  BaseViewController.swift
//  TheDocument
//


import UIKit
import FirebaseStorageUI

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named:"ArrowBack")
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named:"ArrowBack")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension UIImageView {
    
    func loadAvatar(_for friend: TDUser, retry: Bool = false) {
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        
        // Create a storage reference from our storage service
        let photoRef = storage.reference(forURL: "gs://the-document.appspot.com/photos/\(friend.uid)")

        self.sd_setImage(with: photoRef, placeholderImage: UIImage(named: "logo-mark-square"))
    }
}
