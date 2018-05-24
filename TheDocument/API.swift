//
//  API.swift
//  TheDocument
//


import Foundation
import Firebase
import Argo

struct API {
    
    //After login and before home screen operations
    func startup(closure: @escaping (Bool)->Void) {
        Database.database().reference(withPath: "users/\(currentUser.uid)").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userInfo = snapshot.value as? [String : Any] else { closure(false); return }
            
            currentUser.name = userInfo["name"] as? String ?? "Player"
            currentUser.postcode = userInfo["postcode"] as? String ?? ""
            currentUser.phone = userInfo["phone"] as? String ?? ""
            currentUser.synapseUID = userInfo["synapseUID"] as? String ?? ""
            currentUser.walletID = userInfo["walletID"] as? String ?? ""
            currentUser.bankNodeID = userInfo["bankNodeID"] as? String ?? ""
            currentUser.creditNodeID = userInfo["creditNodeID"] as? String ?? ""
            currentUser.checkForGroups(userInfo["groups"] as? [String : Any])
            
            self.profilePhotoExists { exists in
                // UserDefaults.standard.set(exists, forKey: Constants.shouldGetPhotoKey)
                currentUser.getFriends() { closure(true) }
            }
        })
    }
    
    func pushSynapseUID() {
        Database.database().reference(withPath: "users/\(currentUser.uid)/synapseUID").setValue(currentUser.synapseUID)
    }
    
    func pushPhoneNumber() {
        if let phone = currentUser.phone {
            let formattedPhone = phone.toNumeric()
            Database.database().reference(withPath: "users/\(currentUser.uid)/phone").setValue(formattedPhone)
        }
    }
    
    func pushWalletID() {
        Database.database().reference(withPath: "users/\(currentUser.uid)/walletID").setValue(currentUser.walletID)
    }
    
    //Edits user's info invoked from Settings Screen
    //TODO: rename from GroupsgetScoresFor
    func editInfo(newName:String, newPostCode:String?, newPhone:String?, closure: ((Bool)->Void)? = nil) {
        guard !newName.isBlank else { closure?(false); return }
        
        var updatedPhone = newPhone
        if let phone = newPhone {
            updatedPhone = phone.toNumeric()
        }
        
        let userInfo = ["email": currentUser.email, "name": newName, "postcode": newPostCode, "phone": updatedPhone, "synapseUID": currentUser.synapseUID, "walletID": currentUser.walletID, "bankNodeID": currentUser.bankNodeID, "creditNodeID": currentUser.creditNodeID]
        
        Database.database().reference(withPath: "users/\(currentUser.uid)").setValue(userInfo) { error , ref in
            guard error == nil else { closure?(false);return }
            
            currentUser.name = newName
            currentUser.postcode = newPostCode
            currentUser.phone = newPhone
            
            if currentUser.friends.count > 0 {
                currentUser.friends.forEach { friend in
                    Database.database().reference().child("friends/\(friend.uid)").queryOrderedByKey().queryEqual(toValue: "\(currentUser.uid)").observeSingleEvent(of: .value, with: {(snapshot) in
                        if let myself = (snapshot.value as? [String:Any])?["\(currentUser.uid)"] as? [String:Any] {
                            var newMySelf = myself
                            newMySelf["name"] = newName
                            snapshot.ref.child("\(currentUser.uid)").setValue(newMySelf) { error, ref in
                                closure?(error==nil)
                            }
                        }
                    })
                }
            } else {
                closure?(true); return;
            }
        }
    }
    
    //MARK: Helpers
    
    func editScore(winnerId:String, loserId:String, closure: ((Bool)->Void)? = nil) {
        guard !winnerId.isBlank,!loserId.isBlank else { closure?(false); return }
        
        // Increment winner's totalWins
        Database.database().reference().child("users/\(winnerId)/totalWins").observeSingleEvent(of: .value, with: { winSnap in
            let totalWins = (winSnap.value as? Int) ?? 0
            winSnap.ref.setValue(totalWins+1)
        })
        
        // Increment loser's totalLosses
        Database.database().reference().child("users/\(loserId)/totalLosses").observeSingleEvent(of: .value, with: { lossSnap in
            let totalLosses = (lossSnap.value as? Int) ?? 0
            lossSnap.ref.setValue(totalLosses+1)
        })
    }
    
    func getScoresFor(playersIds:[String], closure: @escaping ([String:(Int,Int)])->Void ) {
        var returnScores = [String:(Int,Int)]()
        
        guard playersIds.count > 0 else { closure(returnScores); return  }
        
        for id in Array(Set(playersIds)) {
            
            Database.database().reference().child("users/\(id)").observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let player = snapshot.value as? [String: Any] {
                    let wins   = player["totalWins"] as? Int ?? 0
                    let losses = player["totalLosses"] as? Int ?? 0
                    returnScores[id] = (wins, losses)
                } else {
                    returnScores[id] = (0,0)
                }
                
                if returnScores.keys.count == playersIds.count {
                    closure(returnScores)
                    return
                }
            })
        }
    }

    //Checks if there is a user registered with email address
    func emailRegistered(email: String, closure:@escaping (Bool)->Void) {
        Auth.auth().fetchProviders(forEmail: email) { (listArray, error) in
            closure( listArray != nil )
        }
    }
    
    //Gets friend ID corresponding to the email address
    func getUIDFromMail(email: String, closure:@escaping (String?)->Void) {
        Database.database().reference().child("users").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userInfo = snapshot.value as? [String: [String:Any]] , userInfo.keys.count > 0, let uid = userInfo.keys.first else { closure(nil); return }
            closure(uid)
        })
    }
    
    //Checks if user has uploaded a profile photo
    func profilePhotoExists(closure:@escaping (Bool)->Void ){
        Storage.storage().reference(withPath: "photos/\(currentUser.uid)").getMetadata(completion: { (metadata, error) in
           closure(metadata != nil)
        })
    }
    
    //Sends last online timestamp
    func setLastOnline(){
        Database.database().reference(withPath: "users/\(currentUser.uid)/lastOnline").setValue("\(Date().timeIntervalSince1970)")
    }
}
