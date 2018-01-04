//
//  InviteFriendsViewController.swift
//  TheDocument
//

import Foundation
import UIKit

class InviteFriendsTableViewController: BaseTableViewController {
    
    var friends = [TDUser]()
    fileprivate var filteredFriends = [TDUser]()
    
    enum Mode {
        case group(Group)
        case challenge(Challenge)
        case teamChallenge(Challenge)
    }
    
    var mode:Mode = .group(Group.empty())
    
    var selectedFriendsIds = Set<String>()
    var selectedTeammateIds = Set<String>()
    var selectedCompetitorIds = Set<String>()
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
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
        
        self.navigationController?.navigationBar.shadowImage = Constants.Theme.mainColor.as1ptImage()
        self.navigationController?.navigationBar.setBackgroundImage(Constants.Theme.mainColor.as1ptImage(), for: .default)
        
        let searchBar = searchController.searchBar
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBarContainer.addSubview(searchBar)
        searchBar.sizeToFit()
        setSearchBarFont()
        
        definesPresentationContext = true
        
        searchController.searchBar.barTintColor = Constants.Theme.mainColor
        searchController.searchBar.tintColor = Constants.Theme.mainColor
        
        if case let Mode.group(group) = self.mode {
            friends = getFriends(obj: group)
            navigationItem.title = "Invite"
            
        } else if case let Mode.challenge(challenge) = self.mode {
            friends = getFriends(obj: challenge)
            navigationItem.title = "Select Competitors"
            
        } else if case let Mode.teamChallenge(challenge) = self.mode {
            friends = getFriends(obj: challenge)
            navigationItem.title = "Select Teammate"
            setBarButtonNext()
        }
    }
    
    func getFriends(obj: Any) -> [TDUser] {
        var users: [TDUser] = currentUser.friends
        if let c = obj as? Challenge, let i = c.group, let group = currentUser.groups.first(where: { $0.id == i }) {
            users = group.members + group.invitees
        }
        
        return users.filter{ !self.selectedFriendsIds.contains($0.uid) && currentUser.uid != $0.uid }
    }
    
    func setBarButtonNext() {
        let barButton = doneButton
        barButton?.title = "Next"
        navigationItem.rightBarButtonItem = barButton
    }
    
    func setSearchBarFont() {
        for subView in searchController.searchBar.subviews {
            for searchBarSubView in subView.subviews {
                if let textField = searchBarSubView as? UITextField {
                    textField.font = UIFont(name: "OpenSans", size: 15.0)
                }
            }
        }
    }
    
    func loadChallengeDetailsView(challenge: Challenge) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
        self.dismiss(animated: false) {
            guard let challengeDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "challengeDetailsViewController") as? ChallengeDetailsViewController, let homeViewController = homeVC, homeViewController.containerViewController.childViewControllers.count > 0 else { return }
        
            homeViewController.showOverviewTapped()
            challengeDetailsViewController.challenge = challenge
            if let navController = homeViewController.containerViewController.childViewControllers[0] as? UINavigationController {
                navController.pushViewController(challengeDetailsViewController, animated: false)
                NCVAlertView().showSuccess("Challenge Created!", subTitle: "")
            }
        }
    }
    
    @IBAction func inviteFriends(_ sender: Any) {
        if case let Mode.group( group ) = self.mode {
            // Group Invitation
            API().addFriendsToGroup(friends: friends.filter{ selectedFriendsIds.contains($0.uid) }, group: group  ) { success in
                if success {
                    self.performSegue(withIdentifier: "back_group_details", sender: self)
                }
            }
            
        } else {
            // Challenge Invitation
            if case let Mode.challenge(challenge) = self.mode {
                // 1-on-1 Challenge
                if selectedFriendsIds.count == 0 { self.dismiss(animated: true, completion: nil); return }
                API().challengeFriends(challenge: challenge, friendsIds: selectedFriendsIds ) {
                    
                    if let friendId = self.selectedFriendsIds.first {
                        var newChallenge = challenge
                        newChallenge.toId = friendId
                        newChallenge.fromId = currentUser.uid
                        self.loadChallengeDetailsView(challenge: newChallenge)
                    }
                    
                    return
                }
            } else if case let Mode.teamChallenge(challenge) = self.mode {
                // 2-on-2 Challenge
                if selectedTeammateIds.isEmpty {
                    let currentUserSet = Set([currentUser.uid])
                    selectedTeammateIds = selectedFriendsIds.union(currentUserSet)
                    selectedFriendsIds.removeAll()
                    
                    let barButton = doneButton
                    barButton?.title = "Done"
                    navigationItem.rightBarButtonItem = barButton
                    navigationItem.title = "Select Competitors"
                    
                    friends = getFriends(obj: challenge).filter{ !self.selectedTeammateIds.contains($0.uid) }
                    tableView.reloadData()
                    
                } else {
                    if selectedFriendsIds.count == 0 || selectedTeammateIds.count == 0 { self.dismiss(animated: true, completion: nil); return }
                    API().challengeTeams(challenge: challenge, teammateIds: selectedTeammateIds, competitorIds: selectedFriendsIds ) {
                        
                        var newChallenge = challenge
                        newChallenge.toId = self.selectedFriendsIds.joined(separator: ",")
                        newChallenge.fromId = self.selectedTeammateIds.joined(separator: ",")
                        self.loadChallengeDetailsView(challenge: newChallenge)
                        return
                    }
                }
            }
        }
    }
}

//MARK: UITableView delegate & datasource
extension InviteFriendsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredFriends.count : friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        let item = searchController.isActive ? filteredFriends[indexPath.row] : friends[indexPath.row]
        cell.setup(item, selected: selectedFriendsIds.contains( item.uid ) )
        setImage(id: item.uid, forCell: cell)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let friendId = searchController.isActive ? filteredFriends[indexPath.row].uid : friends[indexPath.row].uid
        let selectionCount = selectedTeammateIds.isEmpty ? selectedFriendsIds.count+1 : selectedFriendsIds.count
        
        if selectedFriendsIds.contains(friendId) {
            selectedFriendsIds.remove(friendId)
        } else if case Mode.group( _ ) = self.mode {
            selectedFriendsIds.insert(friendId)
        } else if selectionCount < 2 {
            selectedFriendsIds.insert(friendId)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

//Mark: Searching
extension InviteFriendsTableViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text else { return }
        self.filterData(searchTerm)
    }
    func filterData( _ searchTerm: String) -> Void {
        
        guard searchTerm.count > 2 else {  return }
        
        filteredFriends = friends.filter { friend -> Bool in
            return friend.name.lowercased().contains(searchTerm.lowercased())
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didDismissSearchController (_ searchController: UISearchController) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
