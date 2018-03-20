//
//  API+Friends.swift
//  TheDocument
//

import Foundation
import Firebase
import Argo

extension API {
    
    func friendFromJSON(_ json: [String: Any]) -> TDUser? {
        let friend: TDUser? = decode(json as Any)
        return friend
    }
    
    //Gets current user's friends
    func getFriends(uid: String? = nil, closure: @escaping ( [TDUser] )->Void) {
        
        let userId = uid ?? currentUser.uid
        Database.database().reference().child("friends").child(userId).observeSingleEvent(of: .value, with: {(snapshot) in
            
            var friendsArray = [TDUser]()
            
            if let friendsList = snapshot.value as? [String : [String:Any]]  {
                let userLookupGroup = DispatchGroup()
                let uids = friendsList.keys + [currentUser.uid]
                for uid in uids {
                    userLookupGroup.enter()
                    Database.database().reference().child("users/\(uid)").observeSingleEvent(of: .value, with: { (userSnap) in
                        guard let userData = userSnap.value as? [String: Any] else {
                            userLookupGroup.leave(); return
                        }
                        
                        if let friend = friendsList[uid] {
                            var friendWithAdditionalInfo = friend
                            friendWithAdditionalInfo["uid"] = uid
                            friendWithAdditionalInfo["name"] = userData["name"]
                            if let fr:TDUser = self.friendFromJSON(friendWithAdditionalInfo) {
                                fr.record.totalWins = userData["totalWins"] as? Int ?? 0
                                fr.record.totalLosses = userData["totalLosses"] as? Int ?? 0
                                friendsArray.append( fr )
                            }
                        } else {
                            currentUser.record.totalWins = userData["totalWins"] as? Int ?? 0
                            currentUser.record.totalLosses = userData["totalLosses"] as? Int ?? 0
                        }
                        
                        userLookupGroup.leave()
                    })
                }
                
                userLookupGroup.notify(queue: .main) {
                    closure(friendsArray)
                }
            }
            else { // Friends List was unable to load; return empty friendsArray
                closure(friendsArray)
            }
        })
    }
    
    func getFriendRecs(uid: String? = nil, closure: @escaping ( [TDUser] )->Void) {
        //let userId = uid ?? currentUser.uid
        Database.database().reference().child("users").observeSingleEvent(of: .value, with: {(snapshot) in
            var friendsArray = [TDUser]()
            if let friendsList = snapshot.value as? [String : [String:Any]]  {
                for key in friendsList.keys {
                    guard let friend = friendsList[key] else { break }
                    var friendWithAdditionalInfo = friend
                    friendWithAdditionalInfo["uid"] = key

                    if let fr:TDUser = self.friendFromJSON(friendWithAdditionalInfo) {
                        friendsArray.append( fr )
                    }
                }
            }
            
            closure(friendsArray)
        })
    }
    
    //Getting the invitation information and list the invitor as a pending friend
    func getInvitation(from uid:String, name: String, closure: ((Bool)->Void)? = nil) {
        let ownFriendData = ["accepted": 0, "name": "\(name)"] as [String : Any]
        
        Database.database().reference().child("friends/\(currentUser.uid)/\(uid)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value == nil {
                Database.database().reference().child("friends/\(currentUser.uid)/\(uid)").setValue(ownFriendData)
                currentUser.getFriends()
            }
        })
    }
    
    //MARK: Friendship
    //Accepts a pending friend
    func acceptFriend(friend:TDUser, closure: @escaping (Bool)->Void) {
        guard !friend.isEmpty else {closure(false);return}
        
        Database.database().reference(withPath: "friends/\(currentUser.uid)/\(friend.uid)/accepted").setValue(1) { error, ref in
            guard error == nil else { log.error(error!); closure(false); return }
            
            let newFriendData = ["accepted":1,"name":currentUser.name] as [String : Any]
            
            Database.database().reference(withPath: "friends/\(friend.uid)/\(currentUser.uid)").setValue(newFriendData) { error, ref in
                guard error == nil else { log.error(error!); closure(false); return}
                
                Notifier().acceptFriend(to: friend.uid)
                closure(true)
            }
        }
    }
    
    //Removes friend from my friends list
    func endFriendship(with friendId:String, closure: @escaping ()->Void) {
        Database.database().reference(withPath: "friends/\(currentUser.uid)/\(friendId)").removeValue() {_,_ in
            closure()
        }
    }
    
    func invite(uid: String? = nil, closure: @escaping (Bool)->Void) {
        guard let userID = uid, currentUser.friends.index(where: { $0.uid == uid}) == nil else { closure(false); return }
        let newFriendData = ["accepted":0, "name":currentUser.name] as [String : Any]
        Database.database().reference(withPath: "friends/\(userID)/\(currentUser.uid)").setValue(newFriendData) { error, ref in
            let success = error == nil
            if success {
                Notifier().friendRequest(to: userID)
                Database.database().reference(withPath: "users/\(currentUser.uid)/invitations").childByAutoId().setValue(userID)
            }
            closure(success)
        }
    }
    
    //Gets the invitations sent from current user - emails list
    func getInvitedList(closure: @escaping ([String])->Void) {
        Database.database().reference(withPath: "users/\(currentUser.uid)/invitations").observeSingleEvent(of: .value, with: { (snapshot) in
            var list = [String]()
            if snapshot.hasChildren() {
                for invitedSnap in snapshot.children {
                    if let email = (invitedSnap as? DataSnapshot)?.value as? String {
                        list.append(email)
                    }
                }
            }
            closure(list)
        })
    }
}
