//
//  API+Groups.swift
//  TheDocument
//

import Foundation
import Firebase

extension API {
    
    
    //Get the groups list of current user
    func getGroups(closure: @escaping ( Bool )->Void) {
        Database.database().reference().child("user-groups/\(currentUser.uid)").observeSingleEvent(of: .value, with: { snapshot in
            guard let userGroupInfo = snapshot.value as? [String : Any] else {
                currentUser.groups.removeAll()
                closure(false); return
            }
            currentUser.checkForGroups(userGroupInfo)
            closure(true)
        })
    }
    
    func getGroupLeaderboards(groups: [Group]) {
        groups.forEach({ group in
            Database.database().reference().child("groups/\(group.id)/leaderboard/").observeSingleEvent(of: .value, with: { (snapshot) in
                guard let recordData = snapshot.value as? [String: [Int]] else { return }
                UserDefaults.standard.set(recordData, forKey: "leaderboard-\(group.id)")
            })
        })
        UserDefaults.standard.synchronize()
    }
    
    func getGroupMembers(group:Group, closure: @escaping ( [TDUser] )->Void) {
        
        Database.database().reference().child("groups/\(group.id)/members/").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let membersData = snapshot.value as? [String:Any] else { closure([]);  return }
            
            var members = [TDUser]()
            let notFriendsIds = [String]()
            
            membersData.forEach{
                if let memberInfo = $0.value as? [String: String], let name = memberInfo["name"], let _ = memberInfo["state"] {
                    let member = TDUser(uid:$0.key, name: name, email: "") // state: state
                    members.append(member)
                }
            }
            
            if notFriendsIds.count == 0 {
                closure(members)
            } else {
                self.getScoresFor(playersIds: notFriendsIds) { scores in
                    scores.forEach { score in
                        if let index = members.index(where: {$0.uid == score.key}) {
                            members[index].record.totalWins = score.value.0
                            members[index].record.totalLosses = score.value.1
                        }
                    }
                    closure(members)
                }
            }
        })
    }
    
    func addGroup(name:String, desc: String, imgData: Data?, closure: @escaping ( Bool )->Void) {
        
        let key = Database.database().reference().child("groups").childByAutoId().key
        
        let group : [String : Any] = ["uid": currentUser.uid, "name": name, "description": desc,
                                      "leaderboard": ["\(currentUser.uid)": [0,0]],
                                      "members": ["\(currentUser.uid)": ["name": "\(currentUser.name)", "state": "own"]]]
        
        let childUpdates : [String : Any] = ["/groups/\(key)": group,
                                             "/user-groups/\(currentUser.uid)/\(key)": ["name": name, "state": "own"]]
        
        Database.database().reference().updateChildValues(childUpdates) { (error, ref) in
            
            if let image = imgData {
                downloadedImages[key] = image
                Storage.storage().reference(withPath: "groups/\(key)").putData(image)
            }
        
            closure(error != nil ? false : true)
        }
    }
    
    func addFriendsToGroup(friends: [TDUser], group: Group, closure: @escaping ( Bool )->Void) {
        
        for friend in friends {
            let childUpdates : [String : Any] = ["/groups/\(group.id)/members/\(friend.uid)": ["name": "\(friend.name)", "state": "invited"],
                                                 "/user-groups/\(friend.uid)/\(group.id)": ["name": "\(group.name)",  "state": "invited"]]
            
            Database.database().reference().updateChildValues(childUpdates) { (error, ref) in
                if error == nil {
                    Notifier().groupRequest(to: friend.uid, group: group)
                }
            }
        }

        closure(true)
    }
    
    func removeMemberFromGroup(member:TDUser, group: Group, closure: @escaping ( Bool )->Void) {
        guard group.state == .own else {  closure(false); return   }
        
        Database.database().reference().child("groups/\(group.id)/members/\(member.uid)").removeValue()
        Database.database().reference().child("groups/\(group.id)/leaderboard/\(member.uid)").removeValue()
        Database.database().reference().child("user-groups/\(member.uid)/\(group.id)").removeValue()
        closure(true)
    }
    
    func acceptGroupInvitation(group: Group, closure: @escaping ( Bool )->Void) {
        
        let childUpdates : [String : Any] = ["/groups/\(group.id)/members/\(currentUser.uid)":      ["name": "\(currentUser.name)", "state": "member"],
                                             "/groups/\(group.id)/leaderboard/\(currentUser.uid)":  [0,0],
                                             "/user-groups/\(currentUser.uid)/\(group.id)":        ["name": "\(group.name)", "state": "member"]]
        
        Database.database().reference().updateChildValues(childUpdates) { (error, ref) in
            closure(true)
        }
    }
    
    func removeGroup(group: Group, closure: @escaping ( Bool )->Void) {
        if group.state == .own {
            getGroupMembers(group: group) { members in
                members.forEach{ member in
                    Database.database().reference().child("user-groups/\(member.uid)/\(group.id)").removeValue()
                }
                Database.database().reference().child("groups/\(group.id)").removeValue()
                Storage.storage().reference(withPath: "groups/\(group.id)").delete()
                closure(true)
            }
        } else {
            
            Database.database().reference().child("user-groups/\(currentUser.uid)/\(group.id)").removeValue()
            Database.database().reference().child("groups/\(group.id)/leaderboard/\(currentUser.uid)").removeValue()
            Database.database().reference().child("groups/\(group.id)/members/\(currentUser.uid)").removeValue()
            closure(true)
        }
    }
}
