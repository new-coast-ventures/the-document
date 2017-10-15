//
//  ChallengeDetailsViewController.swift
//  TheDocument
//


import UIKit
import Firebase

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
    
    var playerOne: Friend!
    @IBOutlet weak var playerOneStackView: UIStackView!
    @IBOutlet weak var playerOneImageView: CircleImageView!
    @IBOutlet weak var playerOneLabel: UILabel!
    
    var playerTwo: Friend!
    @IBOutlet weak var playerTwoStackView: UIStackView!
    @IBOutlet weak var playerTwoImageview: CircleImageView!
    @IBOutlet weak var playerTwoLabel: UILabel!
    
    var playerThree: Friend?
    @IBOutlet weak var playerThreeStackView: UIStackView!
    @IBOutlet weak var playerThreeImageview: CircleImageView!
    @IBOutlet weak var playerThreeLabel: UILabel!
    
    var playerFour: Friend?
    @IBOutlet weak var playerFourStackView: UIStackView!
    @IBOutlet weak var playerFourImageview: CircleImageView!
    @IBOutlet weak var playerFourLabel: UILabel!
    
    @IBOutlet weak var playersContainerView: UIView!

    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengePriceLabel: UILabel!
    @IBOutlet weak var challengeLocationLabel: UILabel!
    @IBOutlet weak var challengeDateLabel: UILabel!
    
    @IBOutlet weak var teamAWinnerLabel: UILabel!
    @IBOutlet weak var teamBWinnerLabel: UILabel!
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
        
        teamAWinnerLabel.isHidden = true
        teamBWinnerLabel.isHidden = true
        resultStackView.isHidden = true
        resultViewDivider.isHidden = true
        
        teamAWinnerLabel.layer.cornerRadius = 3.0
        teamBWinnerLabel.layer.cornerRadius = 3.0
        playersContainerView.layer.dropShadow()
        
        // Load Player Information
        setupTeams()
        
        // Set up the chatter table
        setupChatter()
 
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
            
        case (2, 1): // Past
            actionButton.setTitle("REQUEST REMATCH", for: .normal)
            if challenge.wonByMe() {
                teamAWinnerLabel.backgroundColor = UIColorFromHex(0x2DBE96)
                teamBWinnerLabel.backgroundColor = .clear
            } else {
                teamAWinnerLabel.backgroundColor = .clear
                teamBWinnerLabel.backgroundColor = UIColorFromHex(0x2DBE96)
            }
            
            teamAWinnerLabel.isHidden = false
            teamBWinnerLabel.isHidden = false
            resultStackView.isHidden = false
            resultViewDivider.isHidden = false
            
        default: // User chose winner, Rejected, Win, Other
            actionButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
        
        // Add keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        comments.removeAll()
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove Keyboard observers
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        
        // Remove Firebase observers
        commentsRef.removeAllObservers()
        Database.database().reference().child("users").child(currentUser.uid).removeAllObservers()
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
                guard success, let sSelf = self, let imageData = downloadedImages[sSelf.challenge.fromId] else { return }
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
            acceptChallenge()
    
        case (0, 0) where challenge.isMine() == true: // Waiting for opponent
            cancelChallenge()
            
        case (1, 1) where challenge.declarator.isBlank: // Current
            displayWinnerSelector()
            
        case (1, 1) where challenge.pendingConfirmation() == false: // Opponent declared
            displayConfirmationAlert()
            
        case (2, 1): // Past
            requestRematch()
            
        default:
            self.stopActivityIndicator()
        }
    }
    
    fileprivate func displayWinnerSelector() {
        let alertView = customAlert()
        
        self.buildDeclareSubview()
        if self.challenge.winner != "" {
            if self.challenge.winner.contains(currentUser.uid) {
                checkPlayer1()
            } else {
                checkPlayer2()
            }
        }
        
        alertView.addButton(Constants.challengeDeclareWinnerAlertTitle, backgroundColor: Constants.Theme.authButtonSelectedBGColor) { self.declareWinner() }
        alertView.addButton("Cancel",backgroundColor: UIColor.clear, textColor: Constants.Theme.authButtonNormalBorderColor) {}
        alertView.customSubview = declareSubview
        alertView.showInfo(Constants.challengeDeclareWinnerAlertTitle, subTitle: "")
    }
    
    fileprivate func displayConfirmationAlert() {
        
        let winnerString = challenge.winner.contains(currentUser.uid) ? challenge.teammateNames() : challenge.competitorNames()
        
        let alertView = customAlert()
        alertView.addButton("Yes",backgroundColor: Constants.Theme.authButtonSelectedBGColor) { self.confirmWinner() }
        alertView.addButton("No",backgroundColor: Constants.Theme.deleteButtonBGColor) {  self.denyWinner() }
        alertView.addButton("Cancel",backgroundColor: UIColor.clear, textColor: Constants.Theme.authButtonNormalBorderColor) { self.dismissModal() }
        alertView.showInfo(Constants.challengeDenyWinnerAlertTitle, subTitle: String(format: Constants.challengeDidWinQuestion, winnerString))
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
            print("No tapped")
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
            print("No tapped")
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
            print("No tapped")
        }
        alertView.showNotice("Cancel Challenge?", subTitle: "Are you sure you want to cancel this challenge?")
    }
    
    fileprivate func requestRematch() {
        let alertView = ncvAlert()
        alertView.addButton("Yes", backgroundColor: Constants.Theme.buttonBGColor) {
            API().rematchChallenge(challenge: self.challenge) { success in
                self.actionCompleted(success: success)
            }
        }
        alertView.addButton("No") {
            print("No tapped")
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
        print("Keyboard will show with height: \(keyboardRect.height)")
        commentFormBottomMargin.constant = keyboardRect.height
        chatterTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.height + 10, right: 0)
        self.view.layoutIfNeeded()
        self.scrollToMostRecentComment()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        commentFormBottomMargin.constant = 0
        chatterTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        print("Keyboard will hide and set margin to 0")
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
                    sSelf.chatterTable.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
        
        return cell
    }
}

extension ChallengeDetailsViewController {
    func buildDeclareSubview() {
        
        declareSubview.subviews.forEach{$0.removeFromSuperview()}
        
        let firstImageView = CircleImageView(image: playerOneImageView.image)
        firstImageView.frame = CGRect(x: x,y: spacing,width: 60,height: 60)
        firstImageView.isUserInteractionEnabled = true
        firstImageView.contentMode = .scaleAspectFill
        firstImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChallengeDetailsViewController.checkPlayer1)))
        declareSubview.addSubview(firstImageView)
        
        let secondImageView = CircleImageView(image: playerTwoImageview.image)
        secondImageView.frame = CGRect(x: declareSubview.frame.maxX - x - 60,y: spacing,width: 60,height: 60)
        secondImageView.isUserInteractionEnabled = true
        secondImageView.contentMode = .scaleAspectFill
        secondImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChallengeDetailsViewController.checkPlayer2)))
        declareSubview.addSubview(secondImageView)
        
        let firstNameLabel = UILabel(frame: CGRect(x: 0,y: firstImageView.frame.maxY + spacing,width: side/2 ,height: 30))
        firstNameLabel.text = challenge.teammateNames()
        firstNameLabel.font = UIFont(name: "OpenSans-Bold", size: 15.0)
        firstNameLabel.textColor = Constants.Theme.authButtonSelectedBGColor
        firstNameLabel.adjustsFontSizeToFitWidth = true
        firstNameLabel.minimumScaleFactor = 0.3
        firstNameLabel.textAlignment = .center
        declareSubview.addSubview(firstNameLabel)
        
        let secondNameLabel = UILabel(frame: CGRect(x: firstNameLabel.frame.maxX,y: firstNameLabel.frame.minY,width: firstNameLabel.frame.width,height: firstNameLabel.frame.height))
        secondNameLabel.text = challenge.competitorNames()
        secondNameLabel.font = firstNameLabel.font
        secondNameLabel.textColor = firstNameLabel.textColor
        secondNameLabel.adjustsFontSizeToFitWidth = true
        secondNameLabel.minimumScaleFactor = 0.3
        secondNameLabel.textAlignment = .center
        declareSubview.addSubview(secondNameLabel)
        
        let firstCheckImageView = UIImageView(image: UIImage(named: "Uncheck"))
        firstCheckImageView.center = CGPoint(x: firstNameLabel.center.x, y: firstNameLabel.frame.maxY + spacing * 2)
        firstCheckImageView.tag = won1_tag
        firstCheckImageView.isUserInteractionEnabled = true
        firstCheckImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChallengeDetailsViewController.checkPlayer1)))
        declareSubview.addSubview(firstCheckImageView)
        
        let secondCheckImageView = UIImageView(image: UIImage(named: "Uncheck"))
        secondCheckImageView.center = CGPoint(x: secondNameLabel.center.x, y: firstCheckImageView.center.y)
        secondCheckImageView.tag = won2_tag
        secondCheckImageView.isUserInteractionEnabled = true
        secondCheckImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChallengeDetailsViewController.checkPlayer2)))
        
        declareSubview.addSubview(secondCheckImageView)
    }
    
    @objc func checkPlayer1() {
        DispatchQueue.main.async {
            self.challenge.declarator = currentUser.uid
            (self.declareSubview.viewWithTag(won1_tag) as? UIImageView)?.image = UIImage(named:"Check")
            (self.declareSubview.viewWithTag(won2_tag) as? UIImageView)?.image = UIImage(named:"Uncheck")
            self.challenge.winner = self.challenge.teammateId()
        }
    }
    
    @objc func checkPlayer2() {
        DispatchQueue.main.async {
            self.challenge.declarator = currentUser.uid
            (self.declareSubview.viewWithTag(won1_tag) as? UIImageView)?.image = UIImage(named:"Uncheck")
            (self.declareSubview.viewWithTag(won2_tag) as? UIImageView)?.image = UIImage(named:"Check")
            self.challenge.winner = self.challenge.competitorId()
        }
    }
}

//MARK: API Actions
extension ChallengeDetailsViewController {
    
    func setupTeams() {
        let teamA: [Friend] = challenge.teamA()
        let teamB: [Friend] = challenge.teamB()
        
        playerOne   = teamA[0]
        playerTwo   = teamB[0]
        playerThree = teamA.count == 2 ? teamA[1] : nil
        playerFour  = teamB.count == 2 ? teamB[1] : nil
        
        loadPlayerOne(player: playerOne)
        loadPlayerTwo(player: playerTwo)
        loadPlayerThree(player: playerThree)
        loadPlayerFour(player: playerFour)
    }
    
    func loadPlayerOne(player: Friend) {
        playerOneLabel.text = player.name
        setCompetitorPhoto(uid: player.id, imageView: self.playerOneImageView)
    }
    
    func loadPlayerTwo(player: Friend) {
        playerTwoLabel.text = player.name
        setCompetitorPhoto(uid: player.id, imageView: self.playerTwoImageview)
    }
    
    func loadPlayerThree(player: Friend?) {
        if let p = player {
            playerThreeLabel.text = p.name
            setCompetitorPhoto(uid: p.id, imageView: self.playerThreeImageview)
            playerThreeStackView.isHidden = false
        } else {
            playerThreeStackView.isHidden = true
        }
    }
    
    func loadPlayerFour(player: Friend?) {
        if let p = player {
            playerFourLabel.text = p.name
            setCompetitorPhoto(uid: p.id, imageView: self.playerFourImageview)
            playerFourStackView.isHidden = false
        } else {
            playerFourStackView.isHidden = true
        }
    }
 
    func declareWinner() {
        guard self.challenge.winner != "" else {self.showAlert(message: Constants.Errors.winnerNotSelected.rawValue); return}
        
        self.challenge.details = (self.declareSubview.viewWithTag(details_tag) as? UITextField)?.text ?? ""
        API().declareWinner(challenge: self.challenge) { success in
            if success {
                //currentUser.currentChallenges.removeObject(self.challenge)
                //currentUser.currentChallenges.append(self.challenge)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
            }
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
                    currentUser.totalWins += 1
                    let users = self.challenge.competitorId().components(separatedBy: ",")
                    users.forEach { (uid) in
                        if let frIndex = currentUser.friends.index(where: { $0.id == uid } ) {
                            currentUser.friends[frIndex].loses += 1
                            currentUser.friends[frIndex].winsAgainst += 1
                        }
                    }
                } else {
                    currentUser.totalLosses += 1
                    let users = self.challenge.competitorId().components(separatedBy: ",")
                    users.forEach { (uid) in
                        if let frIndex = currentUser.friends.index(where: { $0.id == uid } ) {
                            currentUser.friends[frIndex].wins += 1
                            currentUser.friends[frIndex].lossesAgainst += 1
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
                //currentUser.currentChallenges.removeObject(self.challenge)
                //currentUser.currentChallenges.append(self.challenge)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                self.navigationController?.popViewController(animated: true)
            } else {
                self.showAlert(message: Constants.Errors.defaultError.rawValue)
            }
        }
    }
}
