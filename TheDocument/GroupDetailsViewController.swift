//
//  GroupDetailsViewController.swift
//  TheDocument
//


import UIKit
import Firebase

class GroupDetailsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var leaderboardDatasource = [GroupMember]()
    var group = Group.empty()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupDetailsStackView: UIStackView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNavigationView: UIView!
    
    @IBOutlet weak var tabStackView: UIStackView!
    @IBOutlet weak var chatterTabButton: TabButton!
    @IBOutlet weak var leaderboardTabButton: TabButton!
    
    @IBOutlet weak var commentFormContainer: UIView!
    @IBOutlet weak var commentForm: UIStackView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var commentSendButton: UIButton!
    @IBOutlet weak var commentFormBottomMargin: NSLayoutConstraint!
    
    let kSectionComments = 0
    let kSectionLeaderboard = 1
    let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(hideControls))
    
    var leaderboardReady: Bool = false
    var chatterMode = false
    var comments: Array<DataSnapshot> = []
    var commentsRef: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupImageView.contentMode = .scaleAspectFill
        
        if let headerView = tableView.tableHeaderView {
            let bottomLine = CALayer()
            bottomLine.frame = CGRect(x: 0.0, y: headerView.frame.height - 1, width: headerView.frame.width, height: 1.0)
            bottomLine.backgroundColor = Constants.Theme.separatorColor.cgColor
            headerView.layer.addSublayer(bottomLine)
        }
        
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named:"ArrowBack")
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named:"ArrowBack")
        
        let nib = UINib(nibName: "ItemCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ItemTableViewCell")
//        tableView.contentInset    = UIEdgeInsets(top: 0, left: 0, bottom: 70.0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(GroupDetailsViewController.refreshMembers), for: .valueChanged)
        
        setupChatter()
        
        if group.state == .invited {
            let alertView = NCVAlertView(appearance: NCVAlertView.NCVAppearance(kTitleFont: UIFont(name: "OpenSans-Bold", size: 16)!, kTextFont: UIFont(name: "OpenSans", size: 14)!, kButtonFont: UIFont(name: "OpenSans-Bold", size: 14)!, showCloseButton: false, showCircularIcon: false, titleColor: Constants.Theme.authButtonSelectedBGColor))
            
            alertView.addButton("Yes",backgroundColor: Constants.Theme.authButtonSelectedBGColor) { self.acceptGroupInvitation() }
            alertView.addButton("No",backgroundColor: Constants.Theme.deleteButtonBGColor) {  self.rejectGroupInvitation() }
            alertView.showInfo("Group Invite", subTitle: "Do you want to join this group?")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
        // Add keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        groupNameLabel.text = group.name
        groupImageView.isHidden = true
        
        appDelegate.downloadImageFor(id: group.id, section: "groups"){[weak self] success in
            guard success, let sSelf = self else { return }
            
            if let imgData = downloadedImages[sSelf.group.id] {
                sSelf.groupImageView.image = UIImage(data: imgData)
                sSelf.groupImageView.layer.cornerRadius = sSelf.groupImageView.frame.size.height / 2.0
                sSelf.groupImageView.layer.masksToBounds = true
                sSelf.groupImageView.layer.borderWidth = 0
                sSelf.groupImageView.isHidden = false
            } else {
                sSelf.groupImageView.isHidden = true
            }
        }
        
        comments.removeAll()
        
        // [START child_event_listener]
        // Listen for new comments in the Firebase database
        commentsRef.observe(.childAdded, with: { (snapshot) -> Void in
            self.comments.append(snapshot)
            let indexPath = IndexPath(row: self.comments.count-1, section: self.kSectionComments)
            //self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            self.tableView.reloadData()
        })
        // Listen for deleted comments in the Firebase database
        commentsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            self.comments.remove(at: index)
            self.tableView.reloadData()
            //self.tableView.deleteRows(at: [IndexPath(row: index, section: self.kSectionComments)], with: UITableViewRowAnimation.automatic)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshMembers()
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
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func setupChatter() {
        let nib = UINib(nibName: "CommentTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "CommentCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        //tableView.tableFooterView = UIView()
        
        chatterMode = false
        leaderboardTabButton.isChecked = true
        chatterTabButton.isChecked = false
        
        commentFormContainer.isHidden = true
        commentFormContainer.addBorder() // default is top, 1px, light gray
        commentsRef = Database.database().reference().child("group-comments").child(group.id)
    }
    
    @objc func hideControls() {
        view.endEditing(true)
    }
    
    func setImage(id: String, forCell cell: ItemTableViewCell, type: String = "photos") {
        guard let challengerId = id.components(separatedBy: ",").first else { return }
        
        if let imageData = downloadedImages[challengerId] {
            cell.setImage(imgData: imageData)
        } else {
            cell.setImageLoading()
            appDelegate.downloadImageFor(id: id, section: type) { success in
                DispatchQueue.main.sync {
                    guard success, let ip = self.tableView.indexPath(for: cell) else { return }
                    if self.tableView.indexPathsForVisibleRows?.contains(ip) == true {
                        self.tableView.reloadRows(at: [ip], with: .none)
                    }
                }
            }
        }
    }
    
    @objc func refreshMembers() {
        self.startActivityIndicator()
        API().getGroupMembers(group: group){ members in
            self.tableView.refreshControl?.endRefreshing()
            self.stopActivityIndicator()
            self.group.members = members
            self.leaderboardDatasource = self.group.members.sorted(by: { $0.wins - $0.loses > $1.wins - $1.loses})
            self.tableView.reloadData()
        }
    }
    
    func acceptGroupInvitation() {
        API().acceptGroupInvitation(group: self.group) { success in
            if success {
                var newGroup = self.group
                newGroup.state = .member
                currentUser.groups.removeObject(newGroup)
                currentUser.groups.append(newGroup)
            }
        }
    }
    
    func rejectGroupInvitation() {
        API().removeGroup(group: self.group) { success in
            currentUser.groups.removeObject(self.group)
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func unwindToGroupDetails(segue: UIStoryboardSegue) {
        if let fromVC = segue.source as? InviteFriendsTableViewController {
            var groupMembersIds = Set<String>(group.members.map{$0.id})
            fromVC.selectedFriendsIds.forEach{ groupMembersIds.insert($0)  }
            tableView.reloadData()
        }
    }
    
    @IBAction func chatterTabButtonTapped(_ sender:TabButton) {
        view.addGestureRecognizer(dismissKeyboardGesture)
        
        leaderboardTabButton.isChecked = false
        chatterTabButton.isChecked = true
        chatterMode = true
        
        self.commentFormContainer.isHidden = false
        self.view.bringSubview(toFront: self.commentFormContainer)
        self.tableView.reloadData()
        self.scrollToMostRecentComment()
    }

    @IBAction func leaderboardTabButtonTapped(_ sender:TabButton) {
        view.removeGestureRecognizer(dismissKeyboardGesture)
        
        leaderboardTabButton.isChecked = true
        chatterTabButton.isChecked = false
        chatterMode = false
        
        self.commentFormContainer.isHidden = true
        leaderboardDatasource = group.members.sorted(by: { $0.wins - $0.loses > $1.wins - $1.loses})
        tableView.reloadData()
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
                    //Notifier().sendChatter(challenge: self.group)
                }
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend(commentSendButton)
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        let keyboardRect = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        print(keyboardRect.height)
        commentFormBottomMargin.constant = keyboardRect.height
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.height + 10, right: 0)
        self.view.layoutIfNeeded()
        self.scrollToMostRecentComment()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
        commentFormBottomMargin.constant = 0
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        self.view.layoutIfNeeded()
        self.scrollToMostRecentComment()
    }
    
    func scrollToMostRecentComment() {
        if comments.count > 0 {
            let bottomIndexPath = IndexPath(row: comments.count - 1, section: kSectionComments)
            tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: false)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == kSectionComments && chatterMode {
            return comments.count
        } else if section == kSectionLeaderboard && !chatterMode {
            return group.members.count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == kSectionComments {
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
                        sSelf.tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
            if !chatterMode && indexPath.row < leaderboardDatasource.count {
                let member = leaderboardDatasource[indexPath.row]
                cell.setup(member, cellId: Int(indexPath.row) + 1)
                setImage(id: member.id, forCell: cell)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.group.state == .own && group.members[indexPath.row].id != currentUser.uid && indexPath.section == kSectionLeaderboard
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let member = group.members[indexPath.row]
            group.members.removeObject(member)
            tableView.reloadData()
            
            API().removeMemberFromGroup(member: member, group: group){[weak self] success in
                if !success {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.groupsRefresh)"), object: nil)
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == kSectionLeaderboard, indexPath.row < leaderboardDatasource.count else { return }
        
        let friend = leaderboardDatasource[indexPath.row].asFriend()
        self.performSegue(withIdentifier: "show_group_user_profile", sender: friend)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.inviteFriendsStoryboardIdentifier, let destinationVC = segue.destination as? InviteFriendsTableViewController {
            destinationVC.selectedFriendsIds = Set(group.members.map{ $0.id  })
            destinationVC.mode = .group(group)
            
        } else if segue.identifier == "show_group_user_profile", let profileVC = segue.destination as? HeadToHeadViewController, let friend = sender as? Friend {
            profileVC.playerTwo = friend
        }
    }
}
