//
//  FriendDetailsViewController.swift
//  TheDocument
//

import UIKit
import FirebaseStorageUI

class FriendDetailsViewController: UIViewController {
    
    @IBOutlet weak var friendImageView: CircleImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var actionButton: AcceptButton!
    @IBOutlet weak var cancelButton: UIButton!
   
    var friend:TDUser!
    var declareSubview = UIView(frame: CGRect(x: 0,y: 0,width: side,height: sideH))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendNameLabel.text = friend.name
        friendImageView.contentMode = .scaleAspectFill
        
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        
        // Create a storage reference from our storage service
        let photoRef = storage.reference(forURL: "gs://the-document.appspot.com/photos/\(friend.uid)")
        
        friendImageView.sd_setImage(with: photoRef, placeholderImage: UIImage(named: "logo-mark-square"))
        
        cancelButton.isHidden = true
        
        switch friend.accepted ?? 0 {
            case 0:
                actionButton.setTitle("\(Constants.acceptButtonTitle)", for: .normal)
                cancelButton.setTitle("\(Constants.friendRequestRejectTitle)", for: .normal)
                cancelButton.isHidden = false
            default: break;
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentUser.getFriends()
    }
    
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        
        switch friend.accepted ?? 0 {
            case 0:
                self.startActivityIndicator()
                API().acceptFriend(friend: friend) { [weak self] success in
                    guard let sSelf = self else { return }
                    
                    sSelf.stopActivityIndicator()
                    
                    if success {
                        if let sFriendIndex = currentUser.friends.index(where: { $0.uid == sSelf.friend.uid }) {
                            currentUser.friends[sFriendIndex].accepted = 1
                        } else {
                            currentUser.getFriends()
                        }
        
                        DispatchQueue.main.async {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        self?.showAlert(message: Constants.Errors.defaultError.rawValue)
                    }
                }
            default: break;
        
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        switch friend.accepted ?? 0 {
        case 0:
            self.startActivityIndicator()
            API().endFriendship(with: friend.uid){ [weak self] in
                DispatchQueue.main.async {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        default: break;
        }
    }

}
