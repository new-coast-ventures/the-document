//
//  DiscoverPeopleTableViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/19/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit
import Branch
import Contacts
import Firebase

class DiscoverPeopleTableViewController: BaseTableViewController {
    
    fileprivate var filteredFriends = [TDUser]()
    fileprivate var sections = [String]()
    
    var selectedIndexpath   : IndexPath? = nil
    var branchInviteObject  : BranchUniversalObject!
    var phoneContacts       : [CNContact] = []
    var users               : [TDUser] = []
    
    let kSectionSearchResults = 0
    let kSectionSuggestions = 1
    
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
        
        self.title = "Discover Friends"
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
        
        users = currentUser.friendRecommendations.alphaSorted()
        tableView.reloadData()
        
        // Get hot and fresh recs
        refreshRecommendations()
        
        // Set up Branch.io invitation object
        branchInviteObject = BranchUniversalObject(canonicalIdentifier: "invite/\(currentUser.uid)")
        branchInviteObject.title = "\(currentUser.name) wants you to try The Document"
        branchInviteObject.contentDescription = "Your friend \(currentUser.name) has invited you to download The Document so you can compete against each other in skills-based challenges."
        branchInviteObject.imageUrl = "http://www.refertothedocument.com/logo.png"
        branchInviteObject.addMetadataKey("userId", value: currentUser.uid)
        branchInviteObject.addMetadataKey("userName", value: currentUser.name)
        
        let linkProperties: BranchLinkProperties = BranchLinkProperties()
        linkProperties.feature = "invites"
        linkProperties.channel = "app"
        
        branchInviteObject.getShortUrl(with: linkProperties) { (url, error) in
            if error == nil {
                print("got my Branch link to share: %@", url!)
                
            } else {
                print(String(format: "Branch error : %@", error! as CVarArg))
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        phoneContacts.removeAll()
        
        /* Phone Contacts */
//        let store = CNContactStore()
//        let keys  = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactImageDataKey, CNContactFormatter.descriptorForRequiredKeys(for: .fullName)] as! [CNKeyDescriptor]
//        let fetch = CNContactFetchRequest(keysToFetch: keys)
//        fetch.sortOrder = .userDefault
//        
//        do {
//            try store.enumerateContacts(with: fetch, usingBlock: { (contact, pointer) in
//                self.phoneContacts.append(contact)
//            })
//            
//            self.tableView.reloadData()
//            
//        } catch let error {
//            print("Error fetching contact: ", error)
//        }
    }
    
    @IBAction func shareInvite(_ sender: Any) {
        branchInviteObject.showShareSheet(withShareText: "Join me on The Document", completion: { (activityType, completed) in
            if (completed) {
                print("Completed sharing to \(activityType!)")
            }
        })
    }
    
    //MARK: BaseTableVC
    override func rowsCount() -> Int { return users.count }
}

//MARK: UITableView delegate & datasource
extension DiscoverPeopleTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case kSectionSearchResults where searchController.isActive:
            return filteredFriends.count
        case kSectionSuggestions where !searchController.isActive:
            return users.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        guard (indexPath.row < users.count) else { return cell }
        
        var contact: TDUser
        switch indexPath.section {
        case kSectionSearchResults where searchController.isActive:
            contact = filteredFriends[indexPath.row]
        case kSectionSuggestions where !searchController.isActive:
            contact = users[indexPath.row]
        default:
            contact = TDUser.empty()
        }

        cell.setup(contact, isSuggestion: true)
        setImage(id: contact.uid, forCell: cell)

//        let contact  = users[indexPath.row]
//        cell.topLabel.text = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
//        cell.bottomLabel.text = primaryPhone(contact) ?? ""
//        cell.isUserInteractionEnabled = true
//        cell.acceptButton.addTarget(self, action: #selector(inviteOrAddFriend), for: .touchUpInside)
//        cell.acceptButton.isUserInteractionEnabled = true
//        
//        let userRef = Database.database().reference().child("users")
//        if let phone = primaryPhone(contact) {
//            let formattedPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
//            userRef.queryOrdered(byChild: "phone").queryEqual(toValue: formattedPhone).observeSingleEvent(of: .value, with: { snapshot in
//                if let userObject = snapshot.value as? [String: [String: Any]] {
//                    if let friendKey = userObject.keys.first {
//                        self.setImage(id: friendKey, forCell: cell)
//                        if currentUser.friends.map({ $0.id }).contains(friendKey) {
//                            cell.acceptButton.isHidden = true
//                        } else {
//                            cell.acceptButton.setTitle("Add", for: .normal)
//                            cell.acceptButton.isHidden = false
//                        }
//                    }
//                } else { // Contact is not a TD user
//                    cell.itemImageView.backgroundColor = Constants.Theme.grayColor
//                    cell.setImage(imgData: Data())
//                    cell.acceptButton.setTitle("Invite", for: .normal)
//                }
//            })
//        } else { // Contact is not a TD user
//            cell.itemImageView.backgroundColor = Constants.Theme.grayColor
//            cell.setImage(imgData: Data())
//            cell.acceptButton.setTitle("Invite", for: .normal)
//        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? ItemTableViewCell {
            cell.acceptButton.isHidden = true
            cell.bottomLabel.text = "Friend request sent!"
            cell.bottomLabel.isHidden = false
        }
        
        var contact: TDUser
        switch indexPath.section {
        case kSectionSearchResults where searchController.isActive:
            contact = filteredFriends[indexPath.row]
        case kSectionSuggestions where !searchController.isActive:
            contact = users[indexPath.row]
        default:
            contact = TDUser.empty()
        }
        
        // Make sure the user isn't already invited
        if !currentUser.invites.contains(contact) {
            setAddFriend(uid: contact.uid, closure: { (added) in
                currentUser.invites.append(contact)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func refreshRecommendations() {
        currentUser.getFriendRecs {
            self.users = currentUser.friendRecommendations.alphaSorted()
            self.tableView.reloadData()
        }
    }
    
    func inviteOrAddFriend() {
        if let ip = selectedIndexpath {
            let contact = users[ip.row]
            setAddFriend(uid: contact.uid, closure: { (added) in
                currentUser.invites.append(contact)
            })
        }
    }
    
    fileprivate func setAddFriend(uid:String, closure:@escaping (Bool)->Void) {
        API().invite(uid: uid, closure: closure)
    }
    
    fileprivate func primaryPhone(_ contact: CNContact) -> String? {
        if let phone = contact.phoneNumbers.first {
            return phone.value.stringValue
        }
        return nil
    }
}

//MARK: Searching
extension DiscoverPeopleTableViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchTerm = searchController.searchBar.text else { return }
        self.filterData(searchTerm)
    }
    
    func filterData( _ searchTerm: String) -> Void {
        guard searchTerm.characters.count > 1 else {  return }
        
        filteredFriends = users.filter { friend -> Bool in
            return friend.name.lowercased().contains(searchTerm.lowercased())
        }
        
        refresh()
    }
    
    func didDismissSearchController (_ searchController: UISearchController) {
        refresh()
    }
}
