//
//  BaseViewController.swift
//  TheDocument
//


import UIKit

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
    
    func loadAvatar(_for friend: Friend, retry: Bool = false) {
        if let imageData = friend.avatarImageData() {
            setAvatarWithData(imageData)
        } else if retry == false {
            appDelegate.downloadImageFor(id: friend.id, section: "photos") { success in
                guard success else { return }
                self.loadAvatar(_for: friend, retry: true)
            }
        }
    }
    
    func setAvatarWithData(_ imgData: Data) {
        DispatchQueue.main.async {
            self.image = UIImage(data: imgData)
        }
    }
}
