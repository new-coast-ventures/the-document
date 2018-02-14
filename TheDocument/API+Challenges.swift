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
        
        // Add challenge price to funds held
        currentUser.updateFundsHeld(amount: Double(challenge.price))
        
        let challengeRef = Database.database().reference().child("challenges")
        
        friendsIds.forEach { friendId in
            var newChallenge = challenge
            newChallenge.toId = friendId
            newChallenge.fromId = currentUser.uid
            newChallenge.participants = [
                [Challenge.Participant(uid: friendId, accepted: -1)],
                [Challenge.Participant(uid: currentUser.uid, accepted: 1)]
            ]
            
            let childUpdates = [
                "/\(friendId)/\(challenge.id)": newChallenge.simplify(),
                "/\(currentUser.uid)/\(challenge.id)": newChallenge.simplify()
            ]
            
            challengeRef.updateChildValues(childUpdates) { (error, ref) in
                Notifier().challengeFriend(challenge: newChallenge, uid: friendId)
                closure()
            }
        }
    }
    
    func challengeTeams(challenge:Challenge, teammateIds:Set<String>, competitorIds:Set<String>, closure: @escaping ( )->Void) {
        guard teammateIds.count > 0 && competitorIds.count > 0 else { closure(); return }
        
        // Add challenge price to funds held
        currentUser.updateFundsHeld(amount: Double(challenge.price))
        
        let challengeRef = Database.database().reference().child("challenges")
        let participantIds = competitorIds.union(teammateIds)
        
        participantIds.forEach { friendId in
            var newChallenge = challenge
            newChallenge.toId = competitorIds.joined(separator: ",")
            newChallenge.fromId = teammateIds.joined(separator: ",")
            newChallenge.participants = [
                competitorIds.map { Challenge.Participant(uid: $0, accepted: -1) },
                teammateIds.map { Challenge.Participant(uid: $0, accepted: 1) }
            ]
            
            let childUpdates = ["/\(friendId)/\(challenge.id)": newChallenge.simplify()]
            challengeRef.updateChildValues(childUpdates) { (error, ref) in
                if friendId != currentUser.uid {
                    Notifier().challengeFriend(challenge: newChallenge, uid: friendId)
                }
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
        newRematchChallenge.fromId = challenge.teammateIds()
        newRematchChallenge.toId = challenge.competitorIds()
        
        if newRematchChallenge.format == "1-on-1" {
            challengeFriends(challenge: newRematchChallenge, friendsIds: [challenge.competitorIds()]) {
                closure(true)
            }
        } else {
            challengeTeams(challenge: newRematchChallenge, teammateIds: [newRematchChallenge.teammateIds()], competitorIds: [newRematchChallenge.competitorIds()], closure: {
                closure(true)
            })
        }
    }

    func cancelChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        let challengeRef = Database.database().reference().child("challenges")
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(challenge.id)"] = NSNull()
        }

        challengeRef.updateChildValues(childUpdates) { (error, ref) in
            if (error != nil) {
                closure(false)
            } else {
                // Refund held challenge funds
                let reimbursement = Double(-1 * challenge.price)
                currentUser.updateFundsHeld(amount: reimbursement)
                closure(true)
            }
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
    
    // Accept Challenge
    func acceptChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        let updatedChallenge = challenge.accept()
        var childUpdates: [String: Any] = [String: Any]()
        
        // Add challenge price to funds held
        currentUser.updateFundsHeld(amount: Double(challenge.price))
        
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(updatedChallenge.id)"] = updatedChallenge.simplify()
        }
        
        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false); return }
            Notifier().acceptChallenge(challenge: updatedChallenge)
            closure(true)
        }
    }
    
    // Reject Challenge
    func rejectChallenge(challenge: Challenge, closure: @escaping ( Bool )->Void) {
        let rejectedChallenge = challenge.reject()
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["/\(uid)/\(challenge.id)"] = rejectedChallenge.simplify()
        }
        
        Database.database().reference().child("challenges").updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false);return }
            Notifier().rejectChallenge(challenge: rejectedChallenge)
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
    
    func confirmWinner(challenge: Challenge, result: String?, closure:@escaping (Bool)->Void) {
        
        var newPastChallenge = challenge
        newPastChallenge.result = result ?? ""
        newPastChallenge.status = 2
        newPastChallenge.accepted = 1
        
        // Refund held challenge funds
        let reimbursement = Double(-1 * challenge.price)
        currentUser.updateFundsHeld(amount: reimbursement)
        
        var challengeHash = newPastChallenge.simplify()
        challengeHash["completedAt"] = [".sv": "timestamp"]
        
        var childUpdates: [String: Any] = [String: Any]()
        challenge.participantIds().forEach { uid in
            childUpdates["challenges/\(uid)/\(newPastChallenge.id)"] = challengeHash
            
            var person: TDUser = TDUser()
            if currentUser.uid == uid {
                person = currentUser
            } else if let frIndex = currentUser.friends.index(where: { $0.uid == uid }) {
                person = currentUser.friends[frIndex]
            }
            
            if challenge.winner.contains(uid) {
                let newWinTotal = (person.record.totalWins ?? 0) + 1
                person.record.totalWins = newWinTotal
                childUpdates["users/\(uid)/totalWins"] = newWinTotal
                
            } else {
                let newLossTotal = (person.record.totalLosses ?? 0) + 1
                person.record.totalLosses = newLossTotal
                childUpdates["users/\(uid)/totalLosses"] = newLossTotal
            }
            
            if let groupId = challenge.group {
                var w = challenge.winner.contains(uid) ? 1 : 0
                var l = challenge.winner.contains(uid) ? 0 : 1
                
                if var groupLeaderboard = UserDefaults.standard.dictionary(forKey: "leaderboard-\(groupId)") as? [String: [Int]],
                    let memberRecord = groupLeaderboard["\(uid)"], memberRecord.count == 2 {
                    w += memberRecord[0]
                    l += memberRecord[1]
                    groupLeaderboard["\(uid)"] = [w, l]
                    UserDefaults.standard.set(groupLeaderboard, forKey: "leaderboard-\(groupId)")
                    UserDefaults.standard.synchronize()
                }
                
                childUpdates["groups/\(groupId)/leaderboard/\(uid)"] = [w, l]
            }
        }
        
        Database.database().reference().updateChildValues(childUpdates) { (error, ref) in
            guard error == nil else { closure(false); return }
            Notifier().confirmWinner(challenge: newPastChallenge)
            closure(true)
        }
    }

}
