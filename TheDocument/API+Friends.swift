//
//  API+Friends.swift
//  TheDocument
//

import Foundation
import Firebase
import Argo

extension API {
    
    func friendFromJSON(_ json: [String: Any]) -> TDUser? {
        if let j: Any = json {
            let friend: TDUser? = decode(j)
            return friend
        }
        return nil
    }
    
    //Gets current user's friends
    func getFriends(uid: String? = nil, closure: @escaping ( [TDUser] )->Void) {
        let userId = uid ?? currentUser.uid
        Database.database().reference().child("friends").child(userId).observeSingleEvent(of: .value, with: {(snapshot) in
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
            guard error == nil else { print("Error accepting friend: \(error?.localizedDescription ?? "")" ); closure(false); return }
            
            print("Accepted friend; creating reverse relationship...")
            let newFriendData = ["accepted":1,"name":currentUser.name] as [String : Any]
            Database.database().reference(withPath: "friends/\(friend.uid)/\(currentUser.uid)").setValue(newFriendData) { error, ref in
                guard error == nil else { print("Error accepting friend: \(error?.localizedDescription ?? "")" ); closure(false); return}
                
                print("Created reverse relationship! Notifying user")
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
