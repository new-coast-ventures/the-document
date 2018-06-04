//
//  FriendsTableViewController.swift
//  TheDocument
//

import UIKit
import Firebase

class FriendsTableViewController: BaseTableViewController {

    fileprivate var filteredFriends = [TDUser]()
    fileprivate var sections = [String]()
    
    var selectedIndexpath:  IndexPath? = nil
    var friends: Array<TDUser> = []
    var friendsRef: DatabaseReference!
    
    let kSectionSearchResults = 0
    let kSectionInvites = 1
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
                friendDataUpdated["uid"] = snapshot.key as AnyObject
                if let friend: TDUser = API().friendFromJSON(friendDataUpdated) {
                    self.friends.append(friend)
                    self.friends.alphaSort()
                    self.refresh()
                }
            }
        })
        
        friendsRef.observe(.childRemoved, with: { (snapshot) -> Void in
            if let index = self.indexOfMessage(snapshot) {
                self.friends.remove(at: index)
                self.refresh()
            }
        })
        
        friendsRef.observe(.childChanged, with: { (snapshot) -> Void in
            if let index = self.indexOfMessage(snapshot), let friendData = snapshot.value as? [String: Any] {
                var friendDataUpdated = friendData
                friendDataUpdated["uid"] = snapshot.key as AnyObject
                if let friend: TDUser = API().friendFromJSON(friendDataUpdated) {
                    self.friends[index] = friend
                    self.refresh()
                }
            }
        })
        
        currentUser.getFriends() {
            self.refresh()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        friendsRef.removeAllObservers()
    }
    
    func indexOfMessage(_ snapshot: DataSnapshot) -> Int? {
        var index = 0
        for friend in self.friends {
            if snapshot.key == friend.uid {
                return index
            }
            index += 1
        }
        return nil
    }
    
    func loadDiscoverFriends() {
        DispatchQueue.main.async {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "discover_friends_nvc") as? UINavigationController {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func discoverFriendsIconPressed(_ sender: Any) {
        self.loadDiscoverFriends()
    }
    
    //MARK: BaseTableVC
    override func rowsCount() -> Int { return currentUser.friends.count }
    override func emptyViewAction() { self.loadDiscoverFriends() }
}

//MARK: IBActions
extension FriendsTableViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? FriendDetailsViewController, let indexPath = selectedIndexpath {
            let friend = friends.filter{ $0.accepted == 0 }[indexPath.row]
            dest.friend = friend
            
        } else if segue.identifier == "show_friend_user_profile", let profileVC = segue.destination as? HeadToHeadViewController, let friend = sender as? TDUser {
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
        case kSectionCurrent where !searchController.isActive:
            return friends.filter{ $0.accepted == 1 }.count
        case kSectionInvites where !searchController.isActive:
            return friends.filter{ $0.accepted == 0 }.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        
        var item: TDUser
        switch indexPath.section {
        case kSectionSearchResults:
            item = filteredFriends[indexPath.row]
        case kSectionCurrent:
            item = friends.filter{ $0.accepted == 1 }[indexPath.row]
        case kSectionInvites:
            item = friends.filter{ $0.accepted == 0 }[indexPath.row]
        default:
            item = TDUser.empty()
        }
        
        var friend = item
        if let friendIndex = friends.index(where: { $0.uid == item.uid }) {
            friend = friends[friendIndex]
        }
        
        cell.setup(friend)
        setImage(id: friend.uid, forCell: cell)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndexpath = indexPath
        switch indexPath.section {
        case kSectionSearchResults:
            let friend = filteredFriends[indexPath.row]
            performSegue(withIdentifier: "show_friend_user_profile", sender: friend)
        case kSectionCurrent:
            let friend = friends.filter{ $0.accepted == 1 }[indexPath.row]
            performSegue(withIdentifier: "show_friend_user_profile", sender: friend)
        case kSectionInvites:
            let friend = friends.filter{ $0.accepted == 0 }[indexPath.row]
            performSegue(withIdentifier: "show_friend_details", sender: friend)
        default:
            return
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section > 0 && searchController.isActive) { return nil }
        switch section {
        case kSectionSearchResults where searchController.isActive,
             kSectionCurrent where !friends.isEmpty:
            return "FRIENDS"
        case kSectionInvites where !friends.filter{ $0.accepted == 0 }.isEmpty:
            return "INVITES"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            var item: TDUser
            switch indexPath.section {
            case kSectionSearchResults:
                item = filteredFriends[indexPath.row]
            case kSectionCurrent:
                item = friends.filter{ $0.accepted == 1 }[indexPath.row]
            case kSectionInvites:
                item = friends.filter{ $0.accepted == 0 }[indexPath.row]
            default:
                item = TDUser.empty()
            }
            
            if !item.isEmpty {
                API().endFriendship(with: item.uid){[weak self] in
                    _ = self?.perform(#selector(FriendsTableViewController.refreshFriends))
                }
            }
        }
    }
    
    func startChallenge(withFriend friend: TDUser) {
        if let newChallengeNavVC = self.storyboard?.instantiateViewController(withIdentifier: "NewChallengeNavVC") as? UINavigationController, let newChallengeVC = newChallengeNavVC.viewControllers.first as? NewChallengeViewController {
            newChallengeVC.toId = friend.uid
            self.present(newChallengeNavVC, animated: true, completion: nil)
        }
    }
}

//MARK: IO
extension FriendsTableViewController {
    @objc func refreshFriends() {
        self.refreshControl?.endRefreshing()
        currentUser.getFriends() {
            self.refresh()
        }
    }
}

//MARK: Searching
extension FriendsTableViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text else { return }
        self.filterData(searchTerm)
    }
    
    func filterData( _ searchTerm: String) -> Void {
        guard searchTerm.count > 1 else { filteredFriends = friends; refresh(); return }

        filteredFriends = friends.filter { friend -> Bool in
            return friend.name.lowercased().contains(searchTerm.lowercased())
        }
        
        refresh()
    }
    
    func didDismissSearchController (_ searchController: UISearchController) {
        refresh()
    }
}

