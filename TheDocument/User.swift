//
//  TDUser.swift
//  TheDocument
//

import FirebaseAuth
import Foundation
import UIKit
import Branch
import Argo
import Curry
import Runes

struct Record {
    var totalWins: Int?
    var totalLosses: Int?
    var winsAgainst: Int = 0
    var lossesAgainst: Int = 0
}

class TDUser {
    let uid: String
    let email: String
    var name: String
    var avatar: UIImage?
    var postcode: String?
    var phone: String?
    var accepted: Int?
    
    // Record Data
    var record = Record()
    
    // SynapseFi Data
    var synapseUID: String?
    var walletID: String?
    var bankNodeID: String?
    var creditNodeID: String?
    
    var synapseData: [String: Any]?
    var nodes: [[String: Any]]?
    var transactions: [[String: Any]]?
    var wallet: [String: Any]?
    
    // Associations
    var groups: [Group] = [Group]()
    var friends: [TDUser] = [TDUser]()
    var invites: [TDUser] = [TDUser]()
    var challenges: [Challenge] = [Challenge]()
    var friendRecommendations: [TDUser] = [TDUser]()
    
    init(uid: String, email: String) {
        self.uid = uid
        self.email = email
        self.name = ""
    }
    
    init(uid: String, name: String, email: String) {
        self.uid = uid
        self.name = name
        self.email = email
    }
    
    init(uid: String, name: String, accepted: Int?, winsAgainst: Int?, lossesAgainst: Int?) {
        self.uid = uid
        self.name = name
        self.email = ""
        self.accepted = accepted ?? 0
        self.record.winsAgainst = winsAgainst ?? 0
        self.record.lossesAgainst = lossesAgainst ?? 0
    }
    
    init() {
        (uid, email, name, postcode, phone, synapseUID, walletID, bankNodeID, creditNodeID) = ("", "", "", "", "", "", "", "", "")
        avatar = #imageLiteral(resourceName: "logo-mark-square")
    }
}

extension TDUser {
    
    var logged:Bool {
        return uid != "" && email != ""
    }
    
    var isLogged:Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isLogged")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isLogged")
            UserDefaults.standard.synchronize()
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        Branch.getInstance().logout()
        API().resetUserKeys()
    }
    
    func startup(closure: @escaping (Bool)->Void) {
        API().startup { success in
            closure(true)
        }
    }
    
    func getChallenges(closure:(()->Void)? = nil) {
        API().getChallenges() { challenges in
            self.challenges = challenges
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
            closure?()
        }
    }
    
    func getFriendRecs(closure:(()->Void)? = nil) {
        API().getFriendRecs() { friendsList in
            
            let allUsers: Set<TDUser> = Set(friendsList)
            let friends:  Set<TDUser> = Set(currentUser.friends + [currentUser])
            let recs = allUsers.subtracting(friends)
            
            currentUser.friendRecommendations = Array(recs)
            closure?()
        }
    }
    
    func getFriends(closure:(()->Void)? = nil) {
        API().getFriends() { friendsList in
            currentUser.friends = friendsList
            closure?()
        }
    }
    
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
                    
                    let group = Group(id: $0.key, name: groupData["name"] ?? "Group", uid: groupData["uid"] ?? currentUser.uid, state: state, members: [currentUser], invitees: [])
                    if !self.groups.contains(group) {
                        self.groups.append(group)
                    }
                }
            }
        }
    }
}

extension TDUser: Argo.Decodable, FirebaseEncodable {
    static func decode(_ json: JSON) -> Decoded<TDUser> {
        return curry(TDUser.init)
            <^> (json <| "uid") as Decoded<String>
            <*> (json <| "name") as Decoded<String>
            <*> (json <|? "accepted") as Decoded<Int?>
            <*> (json <|? "winsAgainst") as Decoded<Int?>
            <*> (json <|? "lossesAgainst") as Decoded<Int?>
    }

    func simplify() -> [String : Any] {
        return ["uid":uid, "email": email, "name": self.name, "postcode": self.postcode as Any, "phone": self.phone as Any, "synapseUID": self.synapseUID as Any, "walletID": self.walletID as Any, "bankNodeID": self.bankNodeID as Any, "creditNodeID": self.creditNodeID as Any]
    }
}

extension TDUser {
    static func empty()->TDUser {
        return TDUser()
    }
    
    var isEmpty:Bool {
        return uid=="" && name==""
    }
    
    func avatarImageData() -> Data? {
        return downloadedImages[self.uid]
    }
}

extension Array where Element == TDUser {
    subscript(id:String)->TDUser {
        
        guard id != currentUser.uid else { return currentUser }
        
        if let foundIndex = self.index(where: { $0.uid == id }) {
            return self[foundIndex]
        }
        
        return TDUser.empty()
    }
    
    func wilsonConfidenceScore(wins: Int, losses: Int, confidence: Double = 0.95) -> Double {
        guard case let n = Double(wins + losses), n != 0 else { return -1.0 }
        
        let z  = 1.96
        let z² = (z * z)
        let p̂  = 1.0 * Double(wins) / n
        
        let lhs = p̂ + z² / (2 * n)
        let rhs = z * sqrt((p̂ * (1 - p̂) + z² / (4 * n)) / n)
        let divisor = 1 + z² / n
        
        let lowerBound = (lhs - rhs) / divisor
        
        return lowerBound
    }
    
    func sortByWilsonRanking() -> [TDUser] {
        return self.sorted {
            return wilsonConfidenceScore(wins: $0.record.totalWins ?? 0, losses: $0.record.totalLosses ?? 0) >
                wilsonConfidenceScore(wins: $1.record.totalWins ?? 0, losses: $1.record.totalLosses ?? 0)
        }
    }
}

extension TDUser: Equatable, Hashable {
    static public func ==(lhs: TDUser, rhs: TDUser) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    var hashValue: Int {
        get {
            return uid.hashValue
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
