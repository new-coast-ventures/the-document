//
//  ChallengeDetailsViewController.swift
//  TheDocument
//


import UIKit
import Firebase
import FacebookShare

let side:CGFloat = 216
let sideH:CGFloat = 186
let spacing:CGFloat = 10
let x = (side - 160) / 2
let won1_tag = 301
let won2_tag = 302
let details_tag = 303

class ChallengeDetailsViewController: UIViewController, UITextFieldDelegate {
    
    let kSectionComments = 0
    //let kSectionSend = 0

    @IBOutlet weak var detailsTabButton: TabButton!
    @IBOutlet weak var chatterTabButton: TabButton!
    
    var playerOne: TDUser!
    @IBOutlet weak var playerOneStackView: UIStackView!
    @IBOutlet weak var playerOneImageView: CircleImageView!
    @IBOutlet weak var playerOneLabel: UILabel!
    @IBOutlet weak var playerOneRecord: UILabel!
    
    var playerTwo: TDUser!
    @IBOutlet weak var playerTwoStackView: UIStackView!
    @IBOutlet weak var playerTwoImageview: CircleImageView!
    @IBOutlet weak var playerTwoLabel: UILabel!
    @IBOutlet weak var playerTwoRecord: UILabel!
    
    var playerThree: TDUser?
    @IBOutlet weak var playerThreeStackView: UIStackView!
    @IBOutlet weak var playerThreeImageview: CircleImageView!
    @IBOutlet weak var playerThreeLabel: UILabel!
    @IBOutlet weak var playerThreeRecord: UILabel!
    
    var playerFour: TDUser?
    @IBOutlet weak var playerFourStackView: UIStackView!
    @IBOutlet weak var playerFourImageview: CircleImageView!
    @IBOutlet weak var playerFourLabel: UILabel!
    @IBOutlet weak var playerFourRecord: UILabel!
    
    @IBOutlet weak var playersContainerView: UIView!

    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengePriceLabel: UILabel!
    @IBOutlet weak var challengeLocationLabel: UILabel!
    @IBOutlet weak var challengeDateLabel: UILabel!
    
    @IBOutlet weak var resultStackView: UIStackView!
    @IBOutlet weak var resultViewDivider: UIView!
    @IBOutlet weak var challengeResultLabel: UILabel!
    
    @IBOutlet weak var wagerStackView: UIStackView!
    @IBOutlet weak var locationStackView: UIStackView!
    @IBOutlet weak var dateStackView: UIStackView!
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var commentFormContainer: UIView!
    @IBOutlet weak var chatterTable: UITableView!
    @IBOutlet weak var commentForm: UIStackView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var commentSendButton: UIButton!
    @IBOutlet weak var commentFormBottomMargin: NSLayoutConstraint!
    
    var challenge:Challenge!
    var chatterMode = false
    var comments: Array<DataSnapshot> = []
    var commentsRef: DatabaseReference!
    var declareSubview = UIView(frame: CGRect(x: 0,y: 0,width: side,height: sideH))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideControls)))
        
        resultStackView.isHidden = true
        resultViewDivider.isHidden = true
        playersContainerView.layer.dropShadow()
        
        // Add keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        // Set up the chatter table
        setupChatter()
        
        // [START child_event_listener]
        // Listen for new comments in the Firebase database
        commentsRef.observe(.childAdded, with: { (snapshot) -> Void in
            self.comments.append(snapshot)
            let indexPath = IndexPath(row: self.comments.count-1, section: self.kSectionComments)
            self.chatterTable.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            self.scrollToMostRecentComment()
        })
        // Listen for deleted comments in the Firebase database
        commentsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            self.comments.remove(at: index)
            self.chatterTable.deleteRows(at: [IndexPath(row: index, section: self.kSectionComments)], with: UITableViewRowAnimation.automatic)
        })
        // [END child_event_listener]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load Player Information
        setupTeams()
        
        // Detail Labels
        challengeNameLabel.text = challenge.challengeName()
        challengePriceLabel.text = (challenge.price == 0) ? "None" : "$\(challenge.price)"
        challengeLocationLabel.text = (challenge.location == "") ? "-" : challenge.location
        challengeDateLabel.text = (challenge.time == "") ? "-" : challenge.time
        challengeResultLabel.text = challenge.result ?? "-"
        
        actionButton.isEnabled = true
        
        switch (challenge.status, challenge.accepted) {
        case (0, 0) where challenge.isMine() == false: // Pending invite
            actionButton.setTitle("ACCEPT CHALLENGE", for: .normal)
            
        case (0, 0) where challenge.isMine() == true: // Waiting for opponent
            actionButton.setTitle("CANCEL CHALLENGE", for: .normal)
            
        case (1, 1) where challenge.declarator.isBlank: // Current
            actionButton.setTitle("END CHALLENGE", for: .normal)
            
        case (1, 1) where challenge.pendingConfirmation() == false: // Opponent declared
            actionButton.setTitle("CONFIRM WINNER", for: .normal)
            
        case (1, 1) where challenge.pendingConfirmation() == true: // Pending confirmation
            actionButton.setTitle("WINNER PENDING...", for: .normal)
            actionButton.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
            actionButton.isEnabled = false
            
        case (1, 2): // Pending payment
            actionButton.setTitle("PAYOUT PENDING...", for: .normal)
            actionButton.backgroundColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0)
            actionButton.isEnabled = false
            
        case (2, 1): // Past
            let buttonText = "SHARE RESULTS"
            actionButton.setTitle(buttonText, for: .normal)
            resultStackView.isHidden = false
            resultViewDivider.isHidden = false
            
        default: // TDUser chose winner, Rejected, Win, Other
            actionButton.isHidden = true
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func indexOfMessage(_ snapshot: DataSnapshot) -> Int {
        var index = 0
        for comment in self.comments {
            if snapshot.key == comment.key {
                return index
            }
            index += 1
        }
        return -1
    }
    
    deinit {
        // Remove Keyboard observers
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        
        // Remove Firebase observers
        commentsRef.removeAllObservers()
        Database.database().reference().child("users").child(currentUser.uid).removeAllObservers()
    }
    
    fileprivate func setupChatter() {
        let nib = UINib(nibName: "CommentTableViewCell", bundle: nil)
        chatterTable.register(nib, forCellReuseIdentifier: "CommentCell")
        chatterTable.rowHeight = UITableViewAutomaticDimension
        chatterTable.estimatedRowHeight = 80
        chatterTable.tableFooterView = UIView()
        
        chatterMode = false
        detailsTabButton.isChecked = true
        chatterTable.isHidden = true
        commentFormContainer.isHidden = true
        commentFormContainer.addBorder() // default is top, 1px, light gray
        commentsRef = Database.database().reference().child("challenge-comments").child(challenge.id)
    }
    
    fileprivate func setCompetitorPhoto(uid: String, imageView: CircleImageView) {
        if let imageData = downloadedImages[uid] {
            DispatchQueue.main.async {
                imageView.image = UIImage(data: imageData)
            }
        } else {
            appDelegate.downloadImageFor(id: uid, section: "photos") { [weak self] success in
                guard success, let imageData = downloadedImages[uid] else { return }
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: imageData)
                }
            }
        }
    }
    
    @objc func hideControls() {
        view.endEditing(true)
    }

    @IBAction func detailsTapped(_ sender: Any) {
        chatterTabButton.isChecked = false
        detailsTabButton.isChecked = true
        chatterMode = false
        
        self.commentFormContainer.isHidden = true
        self.chatterTable.isHidden = true
        self.view.sendSubview(toBack: self.chatterTable)
        self.hideControls()
    }
    
    @IBAction func chatterTapped(_ sender: Any) {
        chatterTabButton.isChecked = true
        detailsTabButton.isChecked = false
        chatterMode = true
        
        self.chatterTable.isHidden = false
        self.view.bringSubview(toFront: self.chatterTable)
        
        self.commentFormContainer.isHidden = false
        self.view.bringSubview(toFront: self.commentFormContainer)
        
        self.scrollToMostRecentComment()
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        switch (challenge.status, challenge.accepted) {
        case (0, 0) where challenge.isMine() == false: // Pending invite
            
            API().getCurrentWalletBalance { balance in
                if balance < Double(self.challenge.price) {
                    self.showAlert(message: "You don't have enough funds to join this challenge. Please add more funds on the Settings page.")
                } else {
                    self.acceptChallenge()
                }
            }
    
        case (0, 0) where challenge.isMine() == true: // Waiting for opponent
            cancelChallenge()
            
        case (1, 1) where challenge.declarator.isBlank: // Current
            declareWinner()
            
        case (1, 1) where challenge.pendingConfirmation() == false: // Opponent declared
            displayConfirmationAlert()
            
        case (2, 1):
            let content = LinkShareContent(url: URL(string: "https://www.refertothedocument.com/")!)
            let shareDialog = ShareDialog(content: content)
            shareDialog.mode = .native
            shareDialog.mode = ShareDialogMode.automatic
            shareDialog.failsOnInvalidData = false
            shareDialog.completion = { result in
            }
            
            do {
                try shareDialog.show()
            } catch {
                self.stopActivityIndicator()
            }
    
        default:
            self.stopActivityIndicator()
        }
    }
    
    func schemeAvailable(scheme: String) -> Bool {
        if let url = URL(string: scheme) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    fileprivate func displayConfirmationAlert() {
        
        var winnerString = "you"
        if challenge.winner == challenge.competitorIds() {
            winnerString += "r opponent"
            if challenge.format != "1-on-1" {
                winnerString += "s"
            }
        } else if challenge.format != "1-on-1" {
            winnerString += "r team"
        }
        
        let alertView = customAlert()
        alertView.addButton("Yes",backgroundColor: Constants.Theme.authButtonSelectedBGColor) { self.confirmWinner() }
        alertView.addButton("No",backgroundColor: Constants.Theme.deleteButtonBGColor) {  self.denyWinner() }
        alertView.addButton("Cancel",backgroundColor: UIColor.clear, textColor: Constants.Theme.authButtonNormalBorderColor) { self.dismissModal() }
        alertView.showInfo("Confirm Winner", subTitle: "Did \(winnerString) win the challenge?")
    }
    
    fileprivate func customAlert() -> NCVAlertView {
        return NCVAlertView(appearance: NCVAlertView.NCVAppearance(kTitleFont: UIFont(name: "OpenSans-Bold", size: 16)!,kTextFont: UIFont(name: "OpenSans", size: 14)!,kButtonFont: UIFont(name: "OpenSans-Bold", size: 14)!,showCloseButton: false, showCircularIcon: false, titleColor: Constants.Theme.authButtonSelectedBGColor))
    }
    
    fileprivate func dismissModal() {
        self.stopActivityIndicator()
    }
    
    fileprivate func acceptChallenge() {
        let alertView = ncvAlert()
        alertView.addButton("Yes", backgroundColor: Constants.Theme.buttonBGColor) {
            API().acceptChallenge(challenge: self.challenge) { success in
                self.actionCompleted(success: success)
            }
        }
        alertView.addButton("No") {
        }
        alertView.showNotice("Accept Challenge?", subTitle: "Do you want to accept this challenge?")
    }
    
    fileprivate func rejectChallenge() {
        let alertView = ncvAlert()
        alertView.addButton("Yes", backgroundColor: Constants.Theme.buttonBGColor) {
            API().rejectChallenge(challenge: self.challenge){ success in
                self.actionCompleted(success: success)
            }
        }
        alertView.addButton("No") {
        }
        alertView.showNotice("Reject Challenge?", subTitle: "Are you sure you want to reject this challenge?")
    }
    
    fileprivate func cancelChallenge() {
        let alertView = ncvAlert()
        alertView.addButton("Yes", backgroundColor: Constants.Theme.buttonBGColor) {
            API().cancelChallenge(challenge: self.challenge) { success in
                self.actionCompleted(success: success)
            }
        }
        alertView.addButton("No") {
        }
        alertView.showNotice("Cancel Challenge?", subTitle: "Are you sure you want to cancel this challenge?")
    }
    
    fileprivate func requestRematch() {
        guard self.challenge.price <= 0 else { return }
        
        let alertView = ncvAlert()
        alertView.addButton("Yes", backgroundColor: Constants.Theme.buttonBGColor) {
            API().rematchChallenge(challenge: self.challenge) { success in
                self.actionCompleted(success: success)
            }
        }
        alertView.addButton("No") {
        }
        alertView.showNotice("Request Rematch?", subTitle: "Are you sure you want a rematch?")
    }
    
    func ncvAlert() -> NCVAlertView {
        let appearance = NCVAlertView.NCVAppearance(
            showCloseButton: false,
            showCircularIcon: false
        )
        return NCVAlertView(appearance: appearance)
    }
    
    fileprivate func actionCompleted(success: Bool) {
        self.stopActivityIndicator()
        if success {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.showAlert(message: Constants.Errors.defaultError.rawValue)
        }
    }

    @IBAction func didTapSend(_ sender: UIButton) {
        commentField.resignFirstResponder()
        commentField.isEnabled = false
        sender.isEnabled = false
        if let commentField = self.commentField {
            let comment = [
                "uid": currentUser.uid,
                "author": currentUser.name,
                "text": commentField.text!
            ]
            
            self.commentsRef.childByAutoId().setValue(comment, withCompletionBlock: { (error, ref) in
                commentField.isEnabled = true
                sender.isEnabled = true
                if error == nil {
                    commentField.text = ""
                    Notifier().sendChatter(challenge: self.challenge)
                }
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend(commentSendButton)
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        commentFormBottomMargin.constant = keyboardRect.height
        chatterTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.height + 10, right: 0)
        self.view.layoutIfNeeded()
        self.scrollToMostRecentComment()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        commentFormBottomMargin.constant = 0
        chatterTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        self.view.layoutIfNeeded()
        self.scrollToMostRecentComment()
    }
    
    func scrollToMostRecentComment() {
        if comments.count > 0 {
            let bottomIndexPath = IndexPath(row: comments.count - 1, section: kSectionComments)
            self.chatterTable.scrollToRow(at: bottomIndexPath, at: .bottom, animated: false)
        }
    }
}

extension ChallengeDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case kSectionComments:
            return comments.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentTableViewCell
        let commentDict = comments[(indexPath as NSIndexPath).row].value as? [String : AnyObject]
        
        if let author = commentDict?["author"], let commentText = commentDict?["text"] {
            cell.authorLabel.text = String(describing: author)
            cell.commentLabel.text = String(describing: commentText)
        }
        
        if let imageId = commentDict?["uid"] as? String {
            if let imageData = downloadedImages[imageId] {
                cell.setImage(imgData: imageData)
            } else {
                appDelegate.downloadImageFor(id: imageId, section: "photos") { [weak self] success in
                    guard success, let sSelf = self else { return }
                    DispatchQueue.main.async {
                        sSelf.chatterTable.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
        
        return cell
    }
}

//MARK: API Actions
extension ChallengeDetailsViewController {
    
    func setupTeams() {
        let teamA: [TDUser] = challenge.teamA()
        let teamB: [TDUser] = challenge.teamB()
        
        playerOne   = teamA[0]
        playerTwo   = teamB[0]
        playerThree = teamA.count == 2 ? teamA[1] : nil
        playerFour  = teamB.count == 2 ? teamB[1] : nil
        
        loadPlayerOne(player: playerOne)
        loadPlayerTwo(player: playerTwo)
        loadPlayerThree(player: playerThree)
        loadPlayerFour(player: playerFour)
    }
    
    func loadPlayerOne(player: TDUser) {
        playerOneLabel.text = player.name
        playerOneRecord.text = competitorRecord(player: player)
        setCompetitorPhoto(uid: player.uid, imageView: self.playerOneImageView)
    }
    
    func loadPlayerTwo(player: TDUser) {
        playerTwoLabel.text = player.name
        playerTwoRecord.text = competitorRecord(player: player)
        setCompetitorPhoto(uid: player.uid, imageView: self.playerTwoImageview)
    }
    
    func loadPlayerThree(player: TDUser?) {
        if let p = player {
            playerThreeLabel.text = p.name
            playerThreeRecord.text = competitorRecord(player: p)
            setCompetitorPhoto(uid: p.uid, imageView: self.playerThreeImageview)
            playerThreeStackView.isHidden = false
        } else {
            playerThreeStackView.isHidden = true
        }
    }
    
    func loadPlayerFour(player: TDUser?) {
        if let p = player {
            playerFourLabel.text = p.name
            playerFourRecord.text = competitorRecord(player: p)
            setCompetitorPhoto(uid: p.uid, imageView: self.playerFourImageview)
            playerFourStackView.isHidden = false
        } else {
            playerFourStackView.isHidden = true
        }
    }
    
    func competitorRecord(player: TDUser?) -> String {
        guard let participant = challenge.participants.flatMap({ $0 }).filter({ $0.uid == player?.uid }).first else { return "" }

        switch participant.accepted {
        case 0:
            return "Declined"
        case 1:
            return "Accepted"
        default:
            return "Pending"
        }
    }
 
    func declareWinner() {
        let alertView = customAlert()
        self.challenge.declarator = currentUser.uid
        
        alertView.addButton(challenge.teammateNames()) {
            self.challenge.winner = self.challenge.teammateIds()
            self.declareWinnerAction()
        }
        
        alertView.addButton(challenge.competitorNames()) {
            self.challenge.winner = self.challenge.competitorIds()
            self.confirmWinner()
        }
        
        alertView.addButton("Cancel", backgroundColor: UIColor.clear, textColor: Constants.Theme.authButtonNormalBorderColor) { self.challenge.declarator = "" }
        
        alertView.showInfo("End Challenge", subTitle: "Who won the challenge?")
    }
    
    func declareWinnerAction() {
        API().declareWinner(challenge: self.challenge) { success in
            if success {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
            }
        }
    }
    
    func payWinner() {
        guard self.challenge.price > 0 else { return }
        
        var playerToPay: TDUser
        if currentUser == playerOne {
            playerToPay = playerTwo
        } else if currentUser == playerTwo {
            playerToPay = playerOne
        } else if currentUser == playerThree {
            playerToPay = playerFour!
        } else {
            playerToPay = playerThree!
        }

        Database.database().reference().child("users").child(playerToPay.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            if let toID = value?["walletID"] as? String, let fromID = currentUser.walletID {
                API().processTransaction(challenge: self.challenge, from: fromID, to: toID, amount: self.challenge.price) { success in
                    if (success) {
                        log.info("Processed transaction")
                    } else {
                        log.error("Transaction failed")
                    }
                }
            } else {
                log.error("Unable to grab walletID from user snapshot")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func confirmWinner() {
        self.challenge.accepted = 2
        
        let alert = customAlert()
        let result = alert.addTextField("")
        
        alert.addButton("Done") {
            API().confirmWinner(challenge: self.challenge, result: result.text) { success in
                guard success else { self.showAlert(message: Constants.Errors.defaultError.rawValue); return }
                
                if self.challenge.winner.contains(currentUser.uid) {
                    let newWinTotal = (currentUser.record.totalWins ?? 0) + 1
                    currentUser.record.totalWins = newWinTotal
                    let users = self.challenge.competitorIds().components(separatedBy: ",")
                    users.forEach { (uid) in
                        if let frIndex = currentUser.friends.index(where: { $0.uid == uid } ) {
                            let newLossTotal = (currentUser.friends[frIndex].record.totalLosses ?? 0) + 1
                            let newWinsAgainst = currentUser.friends[frIndex].record.winsAgainst + 1
                            currentUser.friends[frIndex].record.totalLosses = newLossTotal
                            currentUser.friends[frIndex].record.winsAgainst = newWinsAgainst
                        }
                    }
                } else {
                    
                    if self.challenge.price > 0 {
                        self.payWinner()
                    }
                    
                    let newLossTotal = (currentUser.record.totalLosses ?? 0) + 1
                    currentUser.record.totalLosses = newLossTotal
                    let users = self.challenge.competitorIds().components(separatedBy: ",")
                    users.forEach { (uid) in
                        if let frIndex = currentUser.friends.index(where: { $0.uid == uid } ) {
                            let newTotalWins = (currentUser.friends[frIndex].record.totalWins ?? 0) + 1
                            let newLossesAgainst = currentUser.friends[frIndex].record.lossesAgainst + 1
                            currentUser.friends[frIndex].record.totalWins = newTotalWins
                            currentUser.friends[frIndex].record.lossesAgainst = newLossesAgainst
                        }
                    }
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        alert.showInfo("Record Result", subTitle: "Enter the final score or result of the challenge (optional)")
    }
    
    func denyWinner() {
        API().denyWinner(challenge: self.challenge){ success in
            self.challenge.declarator = ""
            self.challenge.winner = ""
            if success {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
            }
        }
    }
}
