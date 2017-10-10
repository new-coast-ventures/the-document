//
//  FriendDetailsViewController.swift
//  TheDocument
//

import UIKit

class FriendDetailsViewController: UIViewController {
    
    @IBOutlet weak var friendImageView: CircleImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var actionButton: AcceptButton!
    @IBOutlet weak var cancelButton: UIButton!
   
    var friend:Friend!
    var declareSubview = UIView(frame: CGRect(x: 0,y: 0,width: side,height: sideH))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        friendNameLabel.text = friend.name
        friendImageView.contentMode = .scaleAspectFill
        if let imgData = downloadedImages[friend.id] {
            friendImageView.image = UIImage(data: imgData)
        }
        
        cancelButton.isHidden = true
        
        switch friend.accepted {
            case false:
                actionButton.setTitle("\(Constants.acceptButtonTitle)", for: .normal)
                cancelButton.setTitle("\(Constants.friendRequestRejectTitle)", for: .normal)
                cancelButton.isHidden = false
            case true: break;

        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentUser.getFriends()
    }
    
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        
        switch friend.accepted {
            case false:
                self.startActivityIndicator()
                API().acceptFriend(friend: friend) { [weak self] success in
                    guard let sSelf = self else { return }
                    
                    sSelf.stopActivityIndicator()
                    
                    if success {
                        if let friendIndex = currentUser.friends.index(where: { $0.id == sSelf.friend.id }){
                            currentUser.friends[friendIndex].accepted = true
                            currentUser.getScores()
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
            case true:break;
        
        }
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        switch friend.accepted {
        case false: break;
        case true: break;
            
        }
    }

}
