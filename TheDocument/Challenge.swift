//
//  Challenge.swift
//  TheDocument
//
//  accepted -> 0  fromId (self)     Waiting other side to accept
//  accepted -> 0  fromId (not self) Pending
//  accepted -> 1  winner -> ""  OR winner -> (some), declarator (self) Current (winner to be declared)
//  accepted -> 1  winner -> (some), declarator (not self) Current (winner to be confirmed)
//  accepted -> 2  winner -> (some)  Past
//  accepted -> 2  winner -> ""      Past (rejected)

import Foundation
import Argo
import Curry
import Runes

struct Challenge {
    let id: String
    let name: String
    var format:String = "1-on-1"
    let location: String
    let time: String
    var fromId:String = ""
    var toId:String = ""
    var accepted:Int = 0
    var status:Int = 0
    var winner:String = ""
    var price:Int = 0
    var details:String = ""
    var declarator:String = ""
    var completedAt: Double?
    var result: String?
    var group: String?
    
    struct Participant: Argo.Decodable {
        let uid: String
        let accepted: Int
        
        static func decode(_ json: JSON) -> Decoded<Participant> {
            return curry(Participant.init)
                <^> (json <| "uid") as Decoded<String>
                <*> (json <| "accepted") as Decoded<Int>
        }
        
        func simplify() -> [String : Any] {
            return ["uid":uid, "accepted":accepted]
        }
    }
    
    var participants: [[Participant]]
}

extension Challenge {
    
    static func short(name:String?, format:String?, location:String?, time:String?) -> Challenge? {
        guard let chName = name, chName != "", let chFormat = format, chFormat != "", let chLocation = location, let chTime = time else { return nil }
        return Challenge(id: generateRandomString(12), name: chName, format: chFormat, location: chLocation, time: chTime, fromId: "", toId: "", accepted: 0, status: 0, winner: "", price: 0, details: "", declarator: "", completedAt:0, result:"", group:"", participants:[[]])
    }
    
    func simplifiedParticipants() -> [[[String: Any]]] {
        return participants.map({ (team) in
            team.map({ (participant) in
                participant.simplify()
            })
        })
    }
    
    func accept() -> Challenge {
        var updatedChallenge = self
        var updatedParticipants = participants.map({ (team) in
            team.map({ (p) in
                return Participant(uid: p.uid, accepted: (p.uid == currentUser.uid ? 1 : p.accepted))
            })
        })
        updatedChallenge.status = 1
        updatedChallenge.accepted = 1
        updatedChallenge.participants = updatedParticipants
        return updatedChallenge
    }
    
    func reject() -> Challenge {
        var updatedChallenge = self
        var updatedParticipants = participants.map({ (team) in
            team.map({ (p) in
                return Participant(uid: p.uid, accepted: (p.uid == currentUser.uid ? 0 : p.accepted))
            })
        })
        updatedChallenge.status = 2
        updatedChallenge.accepted = 0
        updatedChallenge.winner = ""
        updatedChallenge.declarator = ""
        updatedChallenge.participants = updatedParticipants
        return updatedChallenge
    }
    
    func participantIds()->[String] {
        let a_ids = teamA().map { $0.uid }
        let b_ids = teamB().map { $0.uid }
        return a_ids + b_ids
    }
    
    func loserId()->String {
         return fromId != winner ? fromId : toId
    }
    
    func isMine()->Bool {
        return fromId.contains(currentUser.uid)
    }
    
    func wonByMe()->Bool {
        return winner.contains(currentUser.uid)
    }
    
    func pendingConfirmation()->Bool {
        if teamA().map({ $0.uid }).contains(currentUser.uid) {
            return teamA().map({ $0.uid }).contains(declarator)
        } else {
            return teamB().map { $0.uid }.contains(declarator)
        }
    }
    
    func challengeName() -> String {
        return name
    }
    
    func winnerNames() -> String {
        var names: [String] = [String]()
        let users: [String] = winner.components(separatedBy: ",")
        users.forEach { (uid) in
            if uid == currentUser.uid {
                names.append(currentUser.name)
            } else {
                names.append(currentUser.friends[uid].name)
            }
        }
        
        return names.joined(separator: ", ")
    }
    
    func teammateIds() -> String {
        if teamA().contains(currentUser) {
            return teamAIds()
        } else {
            return teamBIds()
        }
    }
    
    func teammateNames() -> String {
        if teamA().contains(currentUser) {
            return teamANames()
        } else {
            return teamBNames()
        }
    }
    
    func competitorIds() -> String {
        if teamA().contains(currentUser) {
            return teamBIds()
        } else {
            return teamAIds()
        }
    }
    
    func competitorNames() -> String {
        if teamA().contains(currentUser) {
            return teamBNames()
        } else {
            return teamANames()
        }
    }
    
    func teamAIds() -> String {
        return teamA().map { $0.uid }.joined(separator: ",")
    }
    
    func teamANames() -> String {
        return teamA().map { user in
            return user.name
            }.joined(separator: ", ")
    }

    func teamA() -> [TDUser] {
        if let team = participants.first {
            return mapParticipantsToUsers(team: team)
        }
        return []
    }
    
    func teamBIds() -> String {
        return teamB().map { $0.uid }.joined(separator: ",")
    }
    
    func teamBNames() -> String {
        return teamB().map { user in
            return user.name
            }.joined(separator: ", ")
    }

    func teamB() -> [TDUser] {
        if let team = participants.last {
            return mapParticipantsToUsers(team: team)
        }
        return []
    }
    
    func mapParticipantsToUsers(team: [Participant]) -> [TDUser] {
        return team.map({ p in
            return currentUser.friends[p.uid]
        })
    }
}

extension Challenge: Argo.Decodable {
    static func decode(_ json: JSON) -> Decoded<Challenge> {
        let firstPart = curry(Challenge.init)
            <^> (json <| "id") as Decoded<String>
            <*> (json <| "name") as Decoded<String>
            <*> (json <| "format") as Decoded<String>
            
        let secondPart = firstPart
            <*> (json <| "location") as Decoded<String>
            <*> (json <| "time") as Decoded<String>
            <*> (json <| "fromId") as Decoded<String>
            
        let thirdPart = secondPart
            <*> (json <| "toId") as Decoded<String>
            <*> (json <| "accepted") as Decoded<Int>
            <*> (json <| "status") as Decoded<Int>
            
        let fourthPart = thirdPart
            <*> (json <| "winner") as Decoded<String>
            <*> (json <| "price") as Decoded<Int>
            <*> (json <| "details") as Decoded<String>
            
        return fourthPart
            <*> (json <| "declarator") as Decoded<String>
            <*> (json <|? "completedAt") as Decoded<Double?>
            <*> (json <|? "result") as Decoded<String?>
            <*> (json <|? "group") as Decoded<String?>
            <*> (json <|| "participants" >>- { sequence(decodeArray <^> $0) }) as Decoded<[[Participant]]>
    }
    
    func simplify() -> [String : Any] {
        return ["id":id, "name":name, "format":format, "location":location, "time":time, "fromId":fromId, "toId":toId,
                "accepted":accepted, "status":status, "winner":winner, "declarator":declarator, "result":result as Any,
                "completedAt":completedAt as Any, "price":price, "details":details,
                "group":group as Any, "participants":simplifiedParticipants()]
    }
}

extension Challenge: Equatable {
    static public func ==(lhs: Challenge, rhs: Challenge) -> Bool {
        return lhs.id == rhs.id
    }
}
