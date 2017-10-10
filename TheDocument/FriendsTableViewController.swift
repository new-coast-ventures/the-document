//
//  FriendsTableViewController.swift
//  TheDocument
//

import UIKit
import Firebase

class FriendsTableViewController: BaseTableViewController {

    fileprivate var filteredFriends = [Friend]()
    fileprivate var sections = [String]()
    
    var selectedIndexpath:  IndexPath? = nil
    //var friends: Array<DataSnapshot> = []
    var friends: Array<Friend> = []
    var friendsRef: DatabaseReference!
    
    let kSectionSearchResults = 0
    let kSectionPending = 1
    let kSectionCurrent = 2
    
    @IBOutlet weak var searchBarContainer: UIView!
    
    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        return searchController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the Firebase reference
        friendsRef = Database.database().reference().child("friends").child(currentUser.uid)
                
        self.navigationController?.navigationBar.shadowImage = Constants.Theme.mainColor.as1ptImage()
        self.navigationController?.navigationBar.setBackgroundImage(Constants.Theme.mainColor.as1ptImage(), for: .default)
        
        let searchBar = searchController.searchBar
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        searchBarContainer.addSubview(searchBar)
        searchBar.sizeToFit()
        
        definesPresentationContext = true
      
        searchController.searchBar.barTintColor = Constants.Theme.mainColor
        searchController.searchBar.tintColor = Constants.Theme.mainColor
      
        for subView in searchController.searchBar.subviews {
            for searchBarSubView in subView.subviews {
                if let textField = searchBarSubView as? UITextField {
                    textField.font = UIFont(name: "OpenSans", size: 15.0)
                }
            }
        }
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(FriendsTableViewController.refreshFriends), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil)
        
        friends.removeAll()

        friendsRef.observe(.childAdded, with: { (snapshot) -> Void in
            if let friendData = snapshot.value as? [String: Any] {
                var friendDataUpdated = friendData
                friendDataUpdated["friendId"] = snapshot.key as AnyObject
                if let friend: Friend = API().friendFromJSON(friendDataUpdated) {
                    
                    self.friends.append(friend)
                    self.friends.alphaSort()
                    self.tableView.reloadData()
                    
                    //let indexPath = IndexPath(row: self.friends.count-1, section: self.kSectionCurrent)
                    //self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                }
            }
        })
        
        friendsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            self.friends.remove(at: index)
            self.tableView.reloadData()
            
            //self.tableView.deleteRows(at: [IndexPath(row: index, section: self.kSectionCurrent)], with: UITableViewRowAnimation.automatic)
        })
        
        friendsRef.observe(.childChanged, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot)
            if let friendData = snapshot.value as? [String: Any] {
                var friendDataUpdated = friendData
                friendDataUpdated["friendId"] = snapshot.key as AnyObject
                if let friend: Friend = API().friendFromJSON(friendDataUpdated) {
                    self.friends[index] = friend
                    self.tableView.reloadData()
                    
                    //let indexPath = IndexPath(row: self.friends.count-1, section: self.kSectionCurrent)
                    //self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                }
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("View Will Disappear. Removing observers...")
        friendsRef.removeAllObservers()
    }
    
    func indexOfMessage(_ snapshot: DataSnapshot) -> Int {
        var index = 0
        for friend in self.friends {
            if snapshot.key == friend.id {
                return index
            }
            index += 1
        }
        return -1
    }
    
    func refreshDatasource(){
//        
//        print("refreshDatasource")
//        
//        // Get invite list
//        currentUser.getInvitedList()
//        
//        print("Preparing to filter friends list")
//        
//        var newSectionsSet = Set<String>()
//        friends.filter{$0.accepted}.forEach{ newSectionsSet.insert(String($0.name.uppercased().characters.first!)) }
//        
//        print("Filtered friends list")
//        if (friends.filter{ !$0.accepted }.count > 0) {
//            self.sections = [Constants.pendingFriendsTitle]
//        } else {
//            self.sections = []
//        }
//        
//        if Set(sections) != newSectionsSet {
//            self.sections += Array(newSectionsSet)
//        }
//        
//        refresh()
    }
    
    //MARK: BaseTableVC
    override func rowsCount() -> Int { return friends.count }
    override func emptyViewAction() { performSegue(withIdentifier: "discover_friends", sender: self) }
}

//MARK: IBActions
extension FriendsTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? FriendDetailsViewController, let indexPath = selectedIndexpath {
            let friend = friends.filter{ !$0.accepted }[indexPath.row]
            dest.friend = friend
            
        } else if segue.identifier == "show_friend_user_profile", let profileVC = segue.destination as? HeadToHeadViewController, let friend = sender as? Friend {
            profileVC.playerTwo = friend
        }
    }
}

//MARK: UITableView delegate & datasource
extension FriendsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case kSectionSearchResults where searchController.isActive:
            return filteredFriends.count
        case kSectionPending where !searchController.isActive:
            return friends.filter{ !$0.accepted }.count
        case kSectionCurrent where !searchController.isActive:
            return friends.filter{ $0.accepted }.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        
        var item: Friend
        switch indexPath.section {
        case kSectionSearchResults:
            item = filteredFriends[indexPath.row]
        case kSectionPending:
            item = friends.filter{ !$0.accepted }[indexPath.row]
        case kSectionCurrent:
            item = friends.filter{ $0.accepted }[indexPath.row]
        default:
            item = Friend.empty()
        }
        
        var friend = item
        if let friendIndex = currentUser.friends.index(where: { $0.id == item.id }) {
            friend = currentUser.friends[friendIndex]
        }
        
        cell.setup(friend)
        setImage(id: friend.id, forCell: cell)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case kSectionSearchResults:
            let friend = filteredFriends[indexPath.row]
            performSegue(withIdentifier: "show_friend_user_profile", sender: friend)
            //startChallenge(withFriend: friend)
        case kSectionPending:
            selectedIndexpath = indexPath
            performSegue(withIdentifier: Constants.friendDetailsStoryboardIdentifier, sender: self)
        case kSectionCurrent:
            let friend = friends.filter{ $0.accepted }[indexPath.row]
            performSegue(withIdentifier: "show_friend_user_profile", sender: friend)
            //startChallenge(withFriend: friend)
        default:
            return
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
        
        if (section > 0 && searchController.isActive) { return nil }
        switch section {
        case kSectionSearchResults where searchController.isActive,
             kSectionCurrent where !friends.filter{ $0.accepted }.isEmpty:
            return "FRIENDS"
        case kSectionPending where !friends.filter{ !$0.accepted }.isEmpty:
            return "PENDING"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            var item: Friend
            switch indexPath.section {
            case kSectionSearchResults:
                item = filteredFriends[indexPath.row]
            case kSectionPending:
                item = friends.filter{ !$0.accepted }[indexPath.row]
            case kSectionCurrent:
                item = friends.filter{ $0.accepted }[indexPath.row]
            default:
                item = Friend.empty()
            }
            
            if !item.isEmpty {
                API().endFriendship(with: item.id){[weak self] in
                    _ = self?.perform(#selector(FriendsTableViewController.refreshFriends))
                }
            }
        }
    }
    
    func startChallenge(withFriend friend: Friend) {
        if let newChallengeNavVC = self.storyboard?.instantiateViewController(withIdentifier: "NewChallengeNavVC") as? UINavigationController, let newChallengeVC = newChallengeNavVC.viewControllers.first as? NewChallengeViewController {
            newChallengeVC.toId = friend.id
            self.present(newChallengeNavVC, animated: true, completion: nil)
        }
    }
}

//MARK: IO
extension FriendsTableViewController {
    @objc func refreshFriends() {
        self.refreshControl?.endRefreshing()
        //self.startActivityIndicator(style: .gray, location: CGPoint(x: UIScreen.main.bounds.width / 2 , y:  UIScreen.main.bounds.height / 2 ))
        currentUser.getFriends()
    }
}

//MARK: Searching
extension FriendsTableViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text else { return }
        self.filterData(searchTerm)
    }
    func filterData( _ searchTerm: String) -> Void {
        
        guard searchTerm.characters.count > 1 else {  return }
        
        filteredFriends = friends.filter { friend -> Bool in
            return friend.name.lowercased().contains(searchTerm.lowercased())
        }
        
        refresh()
        
    }
    
    func didDismissSearchController (_ searchController: UISearchController) {
        refresh()
    }
}

