//
//  User.swift
//  TheDocument
//

import FirebaseAuth
import Foundation
import UIKit
import Branch

class TDUser {
    
    let uid: String
    let email: String
    var image: UIImage? = nil
    
    var name: String = ""
    var postcode: String = ""
    var phone: String = ""
    var totalWins: Int = 0
    var totalLosses: Int = 0
    
    var groups = [Group]()
    var friends = [Friend]()
    var friendRecommendations = [Friend]()
    var futureChallenges = [Challenge]()
    var currentChallenges = [Challenge]()
    var pastChallenges = [Challenge]()
    
    var hWins = -1
    var hLoses = -1
    
    var invitedList = [String]()
    
    var isLogged:Bool {
        get {
           return UserDefaults.standard.bool(forKey: "isLogged")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isLogged")
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        (uid, email, name, postcode, phone) = ("", "", "", "", "")
    }
    
    init(uid: String, email: String) {
        self.uid = uid
        self.email = email
    }
    
    func logout() {
        try? Auth.auth().signOut()
        Branch.getInstance().logout()
    }
    
    func asFriend() -> Friend {
        return Friend(id: uid, name: name, accepted: true, winsAgainst: 0, lossesAgainst: 0, wins: totalWins, loses: totalLosses)
    }
    
    func asGroupMember() -> GroupMember {
        return GroupMember(id: uid, name: name, state: "member")
    }
}

extension TDUser: FirebaseEncodable {
    func simplify() -> [String : Any] {
        return ["email": email, "name": self.name, "postcode": self.postcode, "phone": self.phone]
    }
}

extension TDUser {
  
    var logged:Bool {
        return uid != "" && email != ""
    }
    
    func startup(closure: @escaping (Bool)->Void) {
        
        API().startup { success in
            guard success else { closure(false); return }
            
            self.getScores() {
                closure(true)
            }
        }
    }
    
    func getChallenges(closure:(()->Void)? = nil) {
        API().getChallenges() { challenges in
            
            self.futureChallenges  = challenges.filter { $0.status == 0 }
            self.currentChallenges = challenges.filter { $0.status == 1 }
            self.pastChallenges    = challenges.filter { $0.status == 2 }.completionSorted()
            
            var headToHeadRecords: [String: [String: Int]?] = [:]
            self.pastChallenges.forEach({ (challenge: Challenge) in
                let competitors: [String] = challenge.competitorId().components(separatedBy: ",")
                competitors.forEach({ (uid) in
                    var currentWins = 0
                    var currentLosses = 0
                    
                    if let competitorData = headToHeadRecords[uid] as? [String: Int] {
                        currentWins = competitorData["wins"]!
                        currentLosses = competitorData["losses"]!
                    }
                    
                    if challenge.wonByMe() {
                        currentWins += 1
                    } else {
                        currentLosses += 1
                    }

                    headToHeadRecords[uid] = ["wins": currentWins, "losses": currentLosses]
                })
            })
            
            headToHeadRecords.forEach({ (record) in
                UserDefaults.standard.set(record.value, forKey: record.key)
            })
            UserDefaults.standard.synchronize()
            
            let newHash = String(self.futureChallenges.filter{$0.accepted == 0}.map{$0.id.characters.first!})
            if !newHash.isEmpty , let oldCandidatesHash = TDCache("challengeCandidates").string , oldCandidatesHash != newHash{
                homeVC?.somethingNewOn(.overview)
            }
            TDCache("challengeCandidates").setValue(newHash)
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
            closure?()
        }
    }
    
    func getFriendRecs(closure:(()->Void)? = nil) {
        API().getFriendRecs() { friendsList in
            
            let allUsers: Set<Friend> = Set(friendsList)
            let friends:  Set<Friend> = Set(currentUser.friends + [currentUser.asFriend()])
            let recs = allUsers.subtracting(friends)
            
            currentUser.friendRecommendations = Array(recs)
            closure?()
        }
    }
    
    func getFriends(closure:(()->Void)? = nil) {
        API().getFriends() { friendsList in
            
            let newHash = "f-\(String(friendsList.filter{!$0.accepted}.map{$0.id.characters.first!}))"
            if let oldCandidatesHash = TDCache("friendCandidates").string , oldCandidatesHash != newHash{
                if homeVC != nil {
                    homeVC?.somethingNewOn(.friends)
                } else {
                    UserDefaults.standard.set("\(UserEvents.showFriendsTab)", forKey: "wokenNotificationType")
                    UserDefaults.standard.synchronize()
                }
            }
            TDCache("friendCandidates").setValue(newHash)
            
            currentUser.friends = friendsList
            self.getScores { closure?() }
        }
    }
    
    func getScores(closure: (()->Void)? = nil) {
        API().getScoresFor(playersIds: currentUser.friends.map{$0.id} + [currentUser.uid]) { scores in
            for (key, score) in scores {
                if let index = currentUser.friends.index(where: { $0.id == key}){
                    currentUser.friends[index].wins = score.0
                    currentUser.friends[index].loses = score.1
                    currentUser.friends[index].lossesAgainst = currentUser.pastChallenges.filter{ $0.winner == key }.count
                    currentUser.friends[index].winsAgainst = currentUser.pastChallenges.filter{ $0.loserId() == key }.count
                } else if key == currentUser.uid {
                    currentUser.totalWins   = score.0
                    currentUser.totalLosses = score.1
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.friendsRefresh)"), object: nil)
            closure?()
        }
    }
    
    func getInvitedList(closure: (()->Void)? = nil) {
        API().getInvitedList() { list in
            self.invitedList = list
            closure?()
        }
    }
}

extension TDUser {
    func checkForGroups(_ groups:[String:Any]?) {
        if let groups = groups {
            groups.forEach {
                if let groupData = $0.value as? [String: String] {
                    
                    var state = GroupState.member
                    if groupData["state"] == "own" {
                        state = GroupState.own
                    } else if groupData["state"] == "invited" {
                        state = GroupState.invited
                    }
                    
                    let group = Group(id: $0.key, name: groupData["name"] ?? "Old Group", uid: groupData["uid"] ?? currentUser.uid, state: state, members: [currentUser.asGroupMember()], invitees: [])
                    if !self.groups.contains(group) {
                        self.groups.append(group)
                    }
                }
            }
        }
    }
}

enum UserEvents:String {
    case friendsRefresh
    case groupsRefresh
    case scoresRefresh
    case needsScores
    case challengesRefresh
    case pastChallengesRefresh
    
    case hideToolbar
    case showToolbar
    
    case showOverviewTab
    case showFriendsTab
    case showGroupsTab
}
