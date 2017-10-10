//
//  API+Challenges.swift
//  TheDocument
//


import Foundation
import Firebase
import Argo

extension API {
    
    func challengeFriends(challenge:Challenge, friendsIds:Set<String>, closure: @escaping ( )->Void) {
        guard friendsIds.count > 0 else { closure(); return }
        
        let challengeRef = Database.database().reference().child("challenges")
        
        friendsIds.forEach { friendId in
            var newChallenge = challenge
            newChallenge.toId = friendId
            newChallenge.fromId = currentUser.uid
            
            let childUpdates = ["/\(friendId)/\(challenge.id)": newChallenge.simplify(), "/\(currentUser.uid)/\(challenge.id)": newChallenge.simplify()]
            challengeRef.updateChildValues(childUpdates) { (error, ref) in
                Notifier().challengeFriend(challenge: newChallenge)
                closure()
            }
        }
    }
    
    func challengeTeams(challenge:Challenge, teammateIds:Set<String>, competitorIds:Set<String>, closure: @escaping ( )->Void) {
        guard teammateIds.count > 0 && competitorIds.count > 0 else { closure(); return }
        
        let challengeRef = Database.database().reference().child("challenges")
        
        let participantIds = competitorIds.union(teammateIds)
        
        participantIds.forEach { friendId in
            print("Creating challenge for participant %@...", friendId)
            
            var newChallenge = challenge
            newChallenge.toId = competitorIds.joined(separator: ",")
            newChallenge.fromId = teammateIds.joined(separator: ",")
            
            let childUpdates = ["/\(friendId)/\(challenge.id)": newChallenge.simplify()]
            challengeRef.updateChildValues(childUpdates) { (error, ref) in
                Notifier().challengeFriend(challenge: newChallenge)
                closure()
            }
        }
    }
    
    func getChallenges(friendId: String = currentUser.uid, closure: @escaping ( [Challenge] )->Void) {
        
        Database.database().reference().child("challenges/\(friendId)").observe(.value, with: {(snapshot) in
            var challenges = [Challenge]()
            let response = snapshot.value as? [String:[String:Any]] ?? [String:[String:Any]]()
            
            response.forEach { challengeData in
                let j: Any = challengeData.value
                if let challenge: Challenge = decode(j) {
                    challenges.append(challenge)
                }
            }
            
            closure(challenges)
        })
    }
    
    private func getChallengeRef(userId:String = currentUser.uid, challenge: Challenge, closure: @escaping ( DatabaseReference? )->Void) {
        
        Database.database().reference().child("challenges/\(userId)/\(challenge.id)").queryOrdered(byChild: "name").queryEqual(toValue: challenge.name).observeSingleEvent(of: .value, with: { (snapshot) in
            closure(snapshot.ref)
        })
    }
    
    func rematchChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        
        guard let newChallenge = Challenge.short(name: challenge.name, format: challenge.format, location: challenge.location, time: challenge.time) else { closure(false); return }
        
        var newRematchChallenge = newChallenge
        newRematchChallenge.fromId = challenge.teammateId()
        newRematchChallenge.toId = challenge.competitorId()
        
        if newRematchChallenge.format == "1-on-1" {
            challengeFriends(challenge: newRematchChallenge, friendsIds: [challenge.competitorId()]) {
                closure(true)
            }
        } else {
            challengeTeams(challenge: newRematchChallenge, teammateIds: [newRematchChallenge.teammateId()], competitorIds: [newRematchChallenge.competitorId()], closure: { 
                closure(true)
            })
        }
    }
    
    func rejectChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        var newPastChallenge = challenge
        newPastChallenge.accepted = 0
        newPastChallenge.status = 2
        newPastChallenge.declarator = ""
        newPastChallenge.winner = ""
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(challenge.id)"] = newPastChallenge.simplify()
        }

        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false);return }
            Notifier().rejectChallenge(challenge: newPastChallenge)
            closure(true)
        }
    }
    
    func cancelChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        let challengeRef = Database.database().reference().child("challenges")
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(challenge.id)"] = NSNull()
        }

        challengeRef.updateChildValues(childUpdates) { (error, ref) in
            closure(error == nil)
        }
    }
 
    func acceptChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        
        var newChallenge = challenge
        newChallenge.status = 1
        newChallenge.accepted = 1
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(newChallenge.id)"] = newChallenge.simplify()
        }
        
        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false);return }
            Notifier().acceptChallenge(challenge: newChallenge)
            closure(true)
        }
    }
    
    func declareWinner(challenge: Challenge, closure:@escaping (Bool)->Void) {
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(challenge.id)"] = challenge.simplify()
        }
        
        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false);return }
            Notifier().declareWinner(challenge: challenge)
            closure(true)
        }
    }
    
    func denyWinner(challenge: Challenge, closure:@escaping (Bool)->Void) {
        
        var newChallenge = challenge
        newChallenge.winner = ""
        newChallenge.declarator = ""
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(newChallenge.id)"] = newChallenge.simplify()
        }
        
        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false);return }
            Notifier().denyWinner(challenge: newChallenge)
            closure(true)
        }
    }
    
    func confirmWinner(challenge: Challenge, closure:@escaping (Bool)->Void) {
        
        var newPastChallenge = challenge
        newPastChallenge.status = 2
        newPastChallenge.accepted = 1
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(newPastChallenge.id)"] = newPastChallenge.simplify()
        }
        
        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false);return }
            Notifier().confirmWinner(challenge: newPastChallenge)
            closure(true)
        }
    }

}
