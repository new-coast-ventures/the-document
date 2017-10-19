//
//  Notifier.swift
//  TheDocument
//

import Foundation

struct Notifier {
    func friendRequest(to uid: String, _ closure : ((Bool) -> Void)? = nil) {
        
        let friendRqRequest = FriendRequestRequest(toUID: uid)
        FCMService().request(request: friendRqRequest, success: { (responce) in
            closure?(true)
        }) { (error) in
            closure?(false)
        }
    }
    
    func acceptFriend(to uid: String, _ closure : ((Bool) -> Void)? = nil) {
        let acceptFrRequest = AcceptFriendRequest(toUID: uid)
        FCMService().request(request: acceptFrRequest, success: { (responce) in
            closure?(true)
        }) { (error) in
            closure?(false)
        }
    }
    
    func challengeFriend(challenge: Challenge, uid: String, _ closure : ((Bool) -> Void)? = nil) {
        let challengeRequest = ChallengeRequest(toUID: uid, challengeId: challenge.id, challengeName: challenge.challengeName())
        FCMService().request(request: challengeRequest, success: { (responce) in
            closure?(true)
        }) { (error) in
            closure?(false)
        }
    }
    
    func acceptChallenge(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let acceptRequest = AcceptChallengeRequest(toUID: uid, challengeId: challenge.id, challengeName: challenge.challengeName())
            FCMService().request(request: acceptRequest, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func sendChatter(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let chatterNotification = ChatterNotification(toUID: uid, challengeId: challenge.id, challengeName: challenge.challengeName())
            FCMService().request(request: chatterNotification, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func sendGroupChatter(group: Group, _ closure : ((Bool) -> Void)? = nil) {
        group.members.forEach { (member) in
            if member.uid != currentUser.uid {
                let uid = member.uid
                let chatterNotification = ChatterNotification(toUID: uid, challengeId: "", challengeName: group.name)
                FCMService().request(request: chatterNotification, success: { (responce) in
                    closure?(true)
                }) { (error) in
                    closure?(false)
                }
            }
        }
    }
    
    func declareWinner(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let declare = DeclareWinner(toUID: uid, challengeId: challenge.id, challengeName: challenge.challengeName(), winnerName: challenge.winnerNames(), winnerID: challenge.winner, declaratorID: challenge.declarator )
            FCMService().request(request: declare, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func confirmWinner(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let confirm = ConfirmWinner(toUID: uid, challengeId:challenge.id, challengeName: challenge.challengeName(), winnerName: challenge.winnerNames())
            FCMService().request(request: confirm, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func denyWinner(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let deny = DenyWinner(toUID: uid, challengeId:challenge.id, challengeName: challenge.challengeName(), winnerName: challenge.winnerNames())
            FCMService().request(request: deny, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func rejectChallenge(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let reject = RejectChallenge(toUID: uid, challengeId: challenge.id, challengeName: challenge.challengeName())
            FCMService().request(request: reject, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func cancelChallenge(challenge: Challenge, _ closure : ((Bool) -> Void)? = nil) {
        let competitors = challenge.competitorId().components(separatedBy: ",")
        competitors.forEach { (uid) in
            let cancel = CancelChallenge(toUID: uid, challengeId: challenge.id, challengeName: challenge.challengeName())
            FCMService().request(request: cancel, success: { (responce) in
                closure?(true)
            }) { (error) in
                closure?(false)
            }
        }
    }
    
    func groupRequest(to uid: String, group: Group, _ closure : ((Bool) -> Void)? = nil) {
        let groupRequest = GroupRequest(toUID: uid, groupName: group.name, groupId: group.id)
        FCMService().request(request: groupRequest, success: { (responce) in
            closure?(true)
        }) { (error) in
            closure?(false)
        }
    }
}
