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
}

extension Challenge {
    
    static func short(name:String?, format:String?, location:String?, time:String?) -> Challenge? {
        guard let chName = name, chName != "", let chFormat = format, chFormat != "", let chLocation = location, let chTime = time else { return nil }
        return Challenge(id: generateRandomString(12), name: chName, format: chFormat, location: chLocation, time: chTime, fromId: "", toId: "", accepted: 0, status: 0, winner: "", price: 0, details: "", declarator: "", completedAt:0, result:"")
    }
    
    func teammateId()->String {
        if fromId.contains(currentUser.uid) {
            return fromId
        } else {
            return toId
        }
    }
    
    func competitorId()->String {
        if fromId.contains(currentUser.uid) {
            return toId
        } else {
            return fromId
        }
    }
    
    func participantIds()->[String] {
        let competitors = competitorId().components(separatedBy: ",")
        let teammates   = teammateId().components(separatedBy: ",")
        return competitors + teammates
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
        return teammateId().contains(declarator)
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
    
    func competitorNames() -> String {
        var names: [String] = [String]()
        let users = competitorId().components(separatedBy: ",")
        users.forEach { (uid) in
            if uid == currentUser.uid {
                names.append("You")
            } else {
                names.append(currentUser.friends[uid].name)
            }
        }
        
        return names.joined(separator: ", ")
    }
    
    func teammateNames() -> String {
        var names: [String] = [String]()
        let users = teammateId().components(separatedBy: ",")
        users.forEach { (uid) in
            if uid == currentUser.uid {
                names.append("You")
            } else {
                names.append(currentUser.friends[uid].name)
            }
        }
        
        return names.joined(separator: ", ")
    }
    
    func teamA() -> [Friend] {
        var teammates: [Friend] = []
        let users = teammateId().components(separatedBy: ",")
        users.forEach { (uid) in
            if uid == currentUser.uid {
                teammates.append(currentUser.asFriend())
            } else {
                teammates.append(currentUser.friends[uid])
            }
        }
        return teammates
    }
    
    func teamB() -> [Friend] {
        var challengers: [Friend] = []
        let users = competitorId().components(separatedBy: ",")
        users.forEach { (uid) in
            if uid == currentUser.uid {
                challengers.append(currentUser.asFriend())
            } else {
                challengers.append(currentUser.friends[uid])
            }
        }
        return challengers
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
    }
    
    func simplify() -> [String : Any] {
        return ["id":id, "name":name, "format":format, "location":location, "time":time, "fromId":fromId, "toId":toId, "accepted":accepted, "status":status, "winner":winner, "declarator":declarator, "result":result, "completedAt":completedAt, "price":price, "details":""]
    }
}

extension Challenge: Equatable {
    static public func ==(lhs: Challenge, rhs: Challenge) -> Bool {
        return lhs.id == rhs.id
    }
}
