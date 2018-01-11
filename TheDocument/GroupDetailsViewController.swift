//
//  GroupDetailsViewController.swift
//  TheDocument
//


import UIKit
import Firebase

class GroupDetailsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var leaderboardDatasource = [TDUser]()
    var group = Group.empty()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var groupDetailsStackView: UIStackView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupNavigationView: UIView!
    @IBOutlet weak var startGroupChallengeButton: UIButton!
    
    @IBOutlet weak var tabStackView: UIStackView!
    @IBOutlet weak var chatterTabButton: TabButton!
    @IBOutlet weak var leaderboardTabButton: TabButton!
    
    @IBOutlet weak var commentFormContainer: UIView!
    @IBOutlet weak var commentForm: UIStackView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var commentSendButton: UIButton!
    @IBOutlet weak var commentFormBottomMargin: NSLayoutConstraint!
    
    let kSectionComments = 0
    let kSectionInvitees = 1
    let kSectionLeaderboard = 2
    
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
        tableView.contentInset    = UIEdgeInsets(top: 0, left: 0, bottom: 70.0, right: 0)
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
        
        // Load leaderboard data
        self.loadLeaderboardData()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
        // Add keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        
        groupNameLabel.text = group.name
        
        appDelegate.downloadImageFor(id: group.id, section: "groups"){[weak self] success in
            DispatchQueue.main.async {
                guard let sSelf = self, let iv = sSelf.groupImageView else { return }
                
                iv.backgroundColor = .clear
                iv.contentMode = .scaleAspectFill
                iv.layer.cornerRadius = iv.frame.size.height / 2.0
                iv.layer.masksToBounds = true
                iv.layer.borderWidth = 0
                iv.isHidden = false
        
                if success == false {
                    iv.backgroundColor = Constants.Theme.mainColor
                    iv.image = UIImage(named: "logo-mark-square")
                    iv.contentMode = .scaleAspectFit
                } else if let imgData = downloadedImages[sSelf.group.id] {
                    iv.image = UIImage(data: imgData)
                }
            }
        }
        
        comments.removeAll()
        
        // [START child_event_listener]
        // Listen for new comments in the Firebase database
        commentsRef.observe(.childAdded, with: { (snapshot) -> Void in
            self.comments.append(snapshot)
            self.tableView.reloadData()
        })
        // Listen for deleted comments in the Firebase database
        commentsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            self.comments.remove(at: index)
            self.tableView.reloadData()
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
        startGroupChallengeButton.isHidden = false
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
            
            if let groupIndex = currentUser.groups.index(where: { $0.id == self.group.id }) {
                currentUser.groups[groupIndex].members = members
            }
            
            self.group.members = members
            self.leaderboardDatasource = self.group.members.sorted {
                let recordA = self.getMemberRecord(uid: $0.uid)
                let recordB = self.getMemberRecord(uid: $1.uid)
                return (recordA[0] - recordA[1]) > (recordB[0] - recordB[1])
            }
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
            var groupMembersIds = Set<String>(group.members.map{$0.uid})
            fromVC.selectedFriendsIds.forEach{ groupMembersIds.insert($0)  }
            tableView.reloadData()
        }
    }
    
    @IBAction func chatterTabButtonTapped(_ sender:TabButton) {
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(dismissKeyboardGesture)
        
        leaderboardTabButton.isChecked = false
        chatterTabButton.isChecked = true
        chatterMode = true
        
        startGroupChallengeButton.isHidden = true
        self.commentFormContainer.isHidden = false
        self.view.bringSubview(toFront: self.commentFormContainer)
        self.tableView.reloadData()
        self.scrollToMostRecentComment()
    }

    @IBAction func leaderboardTabButtonTapped(_ sender:TabButton) {
        view.endEditing(true)
        view.isUserInteractionEnabled = true
        view.removeGestureRecognizer(dismissKeyboardGesture)
        
        leaderboardTabButton.isChecked = true
        chatterTabButton.isChecked = false
        chatterMode = false
        
        self.commentFormContainer.isHidden = true
        startGroupChallengeButton.isHidden = false
        
        leaderboardDatasource = group.members.sorted {
            let recordA = getMemberRecord(uid: $0.uid)
            let recordB = getMemberRecord(uid: $1.uid)
            return (recordA[0] - recordA[1]) > (recordB[0] - recordB[1])
        }
        
        tableView.reloadData()
    }
    
    @IBAction func didTapSend(_ sender: UIButton) {
        if let commentField = self.commentField, let txt = commentField.text, txt != "" {
            commentField.resignFirstResponder()
            commentField.isEnabled = false
            sender.isEnabled = false
            
            let comment = [
                "uid": currentUser.uid,
                "author": currentUser.name,
                "text": txt
            ]
            
            self.commentsRef.childByAutoId().setValue(comment, withCompletionBlock: { (error, ref) in
                commentField.isEnabled = true
                sender.isEnabled = true
                if error == nil {
                    commentField.text = ""
                    Notifier().sendGroupChatter(group: self.group)
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
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.height + 10, right: 0)
        self.view.layoutIfNeeded()
        self.scrollToMostRecentComment()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == kSectionComments && chatterMode {
            return comments.count
        } else if section == kSectionInvitees && !chatterMode {
            return group.invitees.count
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
    
            if indexPath.section == kSectionLeaderboard && indexPath.row < leaderboardDatasource.count {
                let member = leaderboardDatasource[indexPath.row]
                cell.setup(member, cellId: Int(indexPath.row) + 1)
                cell.bottomLabel.text = "0-0"
                setRecordData(uid: member.uid, cell: cell)
                setImage(id: member.uid, forCell: cell)

            } else if indexPath.section == kSectionInvitees && indexPath.row < self.group.invitees.count {
                let member = self.group.invitees[indexPath.row]
                cell.setup(member)
                setImage(id: member.uid, forCell: cell)
            }
            
            return cell
        }
    }
    
    func loadLeaderboardData() {
        Database.database().reference().child("groups/\(group.id)/leaderboard/").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let recordData = snapshot.value as? [String: [Int]] else { return }
            UserDefaults.standard.set(recordData, forKey: "leaderboard-\(self.group.id)")
            UserDefaults.standard.synchronize()
        })
    }
    
    func getMemberRecord(uid: String) -> [Int] {
        guard let groupLeaderboard = UserDefaults.standard.dictionary(forKey: "leaderboard-\(self.group.id)") as? [String: [Int]],
              let memberRecord = groupLeaderboard["\(uid)"], memberRecord.count == 2 else { return [0, 0] }
        
        return memberRecord
    }
    
    func setRecordData(uid: String, cell: ItemTableViewCell) {
        Database.database().reference().child("groups/\(group.id)/leaderboard/\(uid)").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let recordData = snapshot.value as? [Int], recordData.count == 2 else { return }
            DispatchQueue.main.async {
                guard let ip = self.tableView.indexPath(for: cell) else { return }
                if self.tableView.indexPathsForVisibleRows?.contains(ip) == true {
                    cell.bottomLabel.text = "\(recordData[0])-\(recordData[1])"
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case kSectionComments:
            return false
        case kSectionInvitees:
            return group.state == .own && group.invitees[indexPath.row].uid != currentUser.uid
        case kSectionLeaderboard:
            return group.state == .own && group.members[indexPath.row].uid != currentUser.uid
        default:
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            var member: TDUser
            if indexPath.section == kSectionLeaderboard {
                member = group.members[indexPath.row]
                group.members.removeObject(member)
            } else {
                member = group.invitees[indexPath.row]
                group.invitees.removeObject(member)
            }
            
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
        if indexPath.section == kSectionLeaderboard && indexPath.row < leaderboardDatasource.count {
            let friend = leaderboardDatasource[indexPath.row]
            self.performSegue(withIdentifier: "show_group_user_profile", sender: friend)
            
        } else if indexPath.section == kSectionInvitees && indexPath.row < group.invitees.count {
            let friend = group.invitees[indexPath.row]
            self.performSegue(withIdentifier: "show_group_user_profile", sender: friend)
        }
    }
    
    @IBAction func startGroupChallenge(_ sender: Any) {
        if let newChallengeNavVC = self.storyboard?.instantiateViewController(withIdentifier: "NewChallengeNavVC") as? UINavigationController, let newChallengeVC = newChallengeNavVC.viewControllers.first as? NewChallengeViewController {
            newChallengeVC.groupId = group.id
            self.present(newChallengeNavVC, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.inviteFriendsStoryboardIdentifier, let destinationVC = segue.destination as? InviteFriendsTableViewController {
            destinationVC.selectedFriendsIds = Set(group.members.map{ $0.uid })
            destinationVC.mode = .group(group)
            
        } else if segue.identifier == "show_group_user_profile", let profileVC = segue.destination as? HeadToHeadViewController, let friend = sender as? TDUser {
            profileVC.playerTwo = friend
        }
    }
}
