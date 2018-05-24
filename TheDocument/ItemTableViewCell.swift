//
//  ItemTableViewCell.swift
//  TheDocument
//

import UIKit

class ItemTableViewCell: UITableViewCell {

    @IBOutlet weak var cellId: UILabel!
   
    @IBOutlet weak var itemImageViewContainer: UIView!
    @IBOutlet weak var itemImageView: CircleImageView!
    @IBOutlet weak var resultIconImageView: UIImageView!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var acceptButton: AcceptButton!
    
    var item:Any? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.itemImageView.contentMode = .scaleAspectFill
        cleanup()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cleanup()
    }
    
    func cleanup() {
        topLabel.text = ""
        bottomLabel.text = ""
     
        acceptButton.backgroundColor = Constants.Theme.authButtonSelectedBGColor
        acceptButton.layer.borderColorFromUIColor = Constants.Theme.authButtonSelectedBorderColor
        acceptButton.setTitle("", for: .normal)
        acceptButton.isHidden = false
        
        isUserInteractionEnabled = true
        item = nil
        cellId.isHidden = true
        cellId.text = ""
        
        loader.isHidden = false
        
        itemImageView.image = UIImage()
        itemImageView.isHidden = false
        
        resultIconImageView.isHidden = true
    }
    
    //Overview
    func setup(_ item:Challenge) {
        
        self.item = item
        self.topLabel.text = item.challengeName()
        
        switch (item.status, item.accepted) {
        case (0, 0) where !item.fromId.contains(currentUser.uid): // Pending invite
            bottomLabel.text = "\(item.competitorNames()) challenged you"
            actionTitle(title: "Accept")
            
        case (0, 0) where item.fromId.contains(currentUser.uid): // Waiting for opponent
            bottomLabel.text = "Waiting for \(item.competitorNames())"
            acceptButton.isHidden = true
        
        case (1, 1) where item.competitorIds().contains(item.declarator): // Pending confirmation
            bottomLabel.text = "\(item.competitorNames()) chose a winner"
            actionTitle(title: "Confirm")
        
        case (1, 1) where item.declarator.isBlank: // Current
            bottomLabel.text = item.competitorNames()
            actionTitle(title: "End")
        
        case (2, 0) where !item.fromId.contains(currentUser.uid): // Rejected by user
            bottomLabel.text = "Rejected"
            acceptButton.isHidden = true
            
        case (2, 0) where item.fromId.contains(currentUser.uid): // Rejected by opponent
            bottomLabel.text = "Rejected by \(item.competitorNames())"
            acceptButton.isHidden = true
            
        case (2, 1) where !item.winner.contains(currentUser.uid): // Past: Loss
            resultIconImageView.image = #imageLiteral(resourceName: "ErrorIcon")
            resultIconImageView.isHidden = false
            bottomLabel.text = "You lost to \(item.competitorNames())"
            acceptButton.isHidden = true
            
        case (2, 1) where item.winner.contains(currentUser.uid): // Past: Win
            resultIconImageView.image = #imageLiteral(resourceName: "SuccessIcon")
            resultIconImageView.isHidden = false
            bottomLabel.text = "You beat \(item.competitorNames())"
            acceptButton.isHidden = true
            
        default:
            bottomLabel.text = item.competitorNames()
            acceptButton.isHidden = true
        }
        
        // Don't show the button for now
        acceptButton.isHidden = true
    }
    
    fileprivate func actionTitle(title: String) {
        acceptButton.setTitle(title, for: .normal)
        acceptButton.isHidden = false
    }
    
    //Friends
    func setup(_ item:TDUser, cellId:Int? = nil, isSuggestion:Bool = false) {
        
        self.item = item
        self.isUserInteractionEnabled = true
        self.topLabel.text = item.name
        
        if let cellId = cellId {
            self.cellId.text = "\(cellId)"
            self.cellId.isHidden = false
        }
        
        if item.uid == currentUser.uid {
            topLabel.text = Constants.youTitle
            isUserInteractionEnabled = false
        }
        
        if isSuggestion {
            if currentUser.invites.contains(item) {
                acceptButton.isHidden = true
                bottomLabel.text = "Friend request sent!"
                bottomLabel.isHidden = false
            } else {
                bottomLabel.isHidden = true
                acceptButton.isHidden = false
                acceptButton.setTitle("Add", for: .normal)
            }
            
        } else {
            
            acceptButton.isHidden = true
            
            // FIXME: CONVERT TO PENDING
            if false {
                acceptButton.setTitle(Constants.acceptButtonTitle, for: .normal)
                acceptButton.isHidden = false
            }
        }
    }
    
    //Group member
    func setup(_ item:TDUser, cellId:Int? = nil) {
        
        if let cellId = cellId {
            self.cellId.text = "\(cellId)"
            self.cellId.isHidden = false
        }
        
        self.isUserInteractionEnabled = item.uid != currentUser.uid ? true : false
        
        self.item = item
        topLabel.text = item.name
        acceptButton.isHidden = true
        bottomLabel.text = ""
    }
    
    //Invite Friends
    func setup(_ item: TDUser, selected: Bool) {
        self.item = item
        
        topLabel.text = item.name
    
        acceptButton.isHidden = false
        acceptButton.backgroundColor = UIColor.clear
        acceptButton.layer.borderColorFromUIColor = UIColor.clear
        acceptButton.setImage(UIImage(named:  selected  ?  "Check" : "Uncheck"), for: .normal)
    }

    //Groups
    func setup(_ item: Group) {
        topLabel.text = item.name
        acceptButton.isHidden = true
        
        if item.state == .invited {
            acceptButton.setTitle(Constants.acceptButtonTitle, for: .normal)
            acceptButton.isHidden = false
            acceptButton.isUserInteractionEnabled = true
        }
    }
    
    //Invited list
    func setup(_ item: String) {
        loader.isHidden = true
        itemImageView.image = UIImage(named: "Mail")
        topLabel.text = item
        acceptButton.isHidden = true
    }
    
    func setImageLoading() {
        itemImageView.isHidden = true
        loader.startAnimating()
    }
    
    func setGenericImage() {
        loader.stopAnimating()

        DispatchQueue.main.async {
            self.itemImageView.backgroundColor = Constants.Theme.mainColor
            self.itemImageView.image = UIImage(named: "logo-mark-square")
            self.itemImageView.contentMode = .scaleAspectFit
            self.itemImageView.layer.cornerRadius = self.itemImageView.frame.size.height / 2.0
            self.itemImageView.layer.masksToBounds = true
            self.itemImageView.layer.borderWidth = 0
            self.itemImageView.isHidden = false
        }
    }
    
    func setImage(imgData:Data) {
        loader.stopAnimating()
        
        DispatchQueue.main.async {
            self.itemImageView.backgroundColor = .clear
            self.itemImageView.image = UIImage(data: imgData)
            self.itemImageView.contentMode = .scaleAspectFill
            self.itemImageView.layer.cornerRadius = self.itemImageView.frame.size.height / 2.0
            self.itemImageView.layer.masksToBounds = true
            self.itemImageView.layer.borderWidth = 0
            self.itemImageView.isHidden = false
        }
    }
}
