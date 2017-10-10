//
//  API+Groups.swift
//  TheDocument
//

import Foundation
import Firebase

extension API {
    
    
    //Get the groups list of current user
    func getGroups(closure: @escaping ( Bool )->Void) {
        Database.database().reference().child("users/\(currentUser.uid)/groups/").observeSingleEvent(of: .value, with: { snapshot in
            guard let userGroupInfo = snapshot.value as? [String : Any] else { closure(false); return }
            currentUser.checkForGroups(userGroupInfo)
            closure(true)
        })
    }
    
    func getGroupMembers(group:Group, closure: @escaping ( [GroupMember] )->Void) {
        
        Database.database().reference().child("groups/\(group.id)/members/").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let membersData = snapshot.value as? [String:String] else { closure([]);  return   }
            
            var members = [GroupMember]()
            var notFriendsIds = [String]()
            membersData.forEach{
                var member = GroupMember(id:$0.key, name:$0.value)
                
                if member.isFriend {
                    let friend = currentUser.friends[member.id]
                    member.wins = friend.wins
                    member.loses = friend.loses
                    member.hWins = friend.lossesAgainst
                    member.hLoses = friend.winsAgainst
                } else {
                    notFriendsIds.append(member.id)
                }
                members.append(member)
            }
            
            if notFriendsIds.count == 0 {
                closure(members)
            } else {
                self.getScoresFor(playersIds: notFriendsIds) { scores in
                    scores.forEach { score in
                        if let index = members.index(where: {$0.id == score.key}) {
                            members[index].wins = score.value.0
                            members[index].loses = score.value.1
                        }
                    }
                    
                    closure(members)
                }
            }
        })
    }
    
    func addGroup(name:String, desc: String, imgData: Data?, closure: @escaping ( Bool )->Void) {
        
        let key = Database.database().reference().child("groups").childByAutoId().key
        let group : [String : Any] = ["uid": currentUser.uid, "name": name, "description": desc, "members": ["\(currentUser.uid)": "\(currentUser.name)"]]
        let userGroup = ["name": name, "state": "own"]
        
        let childUpdates : [String : Any] = ["/groups/\(key)": group,
                                             "/users/\(currentUser.uid)/groups/\(key)": userGroup]
        
        Database.database().reference().updateChildValues(childUpdates) { (error, ref) in
            
            if let image = imgData {
                downloadedImages[key] = image
                Storage.storage().reference(withPath: "groups/\(key)").putData(image)
            }
        
            closure(error != nil ? false : true)
        }
    }
    
    func addFriendsToGroup(friends: [Friend], group: Group, closure: @escaping ( Bool )->Void) {
        
        for friend in friends {
            let childUpdates : [String : Any] = ["/groups/\(group.id)/members/\(friend.id)": "\(friend.name)",
                                                 "/users/\(friend.id)/groups/\(group.id)": ["name": "\(group.name)", "state": "invited"]]
            
            Database.database().reference().updateChildValues(childUpdates) { (error, ref) in
                if error == nil {
                    Notifier().groupRequest(to: friend.id, group: group)
                }
            }
        }

        closure(true)
    }
    
    func removeMemberFromGroup(member:GroupMember, group: Group, closure: @escaping ( Bool )->Void) {
        guard group.state == .own else {  closure(false); return   }
        
        Database.database().reference().child("groups/\(group.id)/members/\(member.id)").removeValue()
        Database.database().reference().child("users/\(currentUser.uid)/groups/\(group.id)").removeValue()
        closure(true)
    }
    
    func acceptGroupInvitation(group: Group, closure: @escaping ( Bool )->Void) {
        
        Database.database().reference().child("groups/\(group.id)").observeSingleEvent(of: .value, with: { snapshot in
            
//            guard snapshot.exists() else {
//                Database.database().reference().child("users/\(currentUser.uid)/groups/invited/\(group.id)").removeValue()
//                closure(false)
//                return
//            }
        
            Database.database().reference().child("groups/\(group.id)/members/\(currentUser.uid)/").setValue("\(currentUser.name)") { error, ref in
                guard error == nil else { closure(false); return }
                Database.database().reference().child("users/\(currentUser.uid)/groups/\(group.id)").setValue(["name": "\(group.name)", "state": "member"])
                closure(true)
            }
        })
    }
    
    //Removes self from group if not owner (Leaves)
    //Removes whole group if owner
    func removeGroup(group: Group, closure: @escaping ( Bool )->Void) {
        if group.state == .own {
            getGroupMembers(group: group) { members in
                members.forEach{ member in
                    Database.database().reference().child("users/\(member.id)/groups/\(group.id)").removeValue()
                }
                Database.database().reference().child("groups/\(group.id)").removeValue()
                Storage.storage().reference(withPath: "groups/\(group.id)").delete()
                closure(true)
            }
        } else {
            
            Database.database().reference().child("users/\(currentUser.uid)/groups/\(group.id)").removeValue()
            Database.database().reference().child("groups/\(group.id)/members/\(currentUser.uid)").removeValue()
            closure(true)
        }
    }
}
