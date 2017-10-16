//
//  Group.swift
//  TheDocument
//
// 0: Invited in group
// 1: Member of group
// 2: Own group

import Foundation


enum GroupState: Int {
    case invited
    case member
    case own
}

struct Group {
    let id:String
    let name:String
    let uid:String
    var state: GroupState
    var members:[GroupMember]
    var invitees:[GroupMember]
}

extension Group {
    static func empty()->Group {
        return Group(id: "", name: "", uid: "", state: .own, members: [], invitees: [])
    }
}

extension Group: Equatable {
    static public func ==(lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id
    }
}


struct GroupMember {
    let id: String
    let name: String
    let state: String
    
    var wins = -1
    var loses = -1
    var hWins = -1
    var hLoses = -1
    
    init(id: String, name: String, state: String){
        self.id = id
        self.name = name
        self.state = state
        
        wins = -1
        loses = -1
        hWins = -1
        hLoses = -1
    }
}

extension GroupMember: Equatable {
    static public func ==(lhs: GroupMember, rhs: GroupMember) -> Bool {
        return lhs.id == rhs.id
    }
    
    var isMember: Bool {
        if state == "invited" {
            return false
        }
        return true
    }
    
    var isFriend: Bool {
        return currentUser.uid == id || !currentUser.friends[id].isEmpty
    }
    
    func asFriend() -> Friend {
        let friend = currentUser.friends[id]
        return friend.isEmpty ? Friend(id: id, name: name, accepted: true, winsAgainst: -1, lossesAgainst: -1, wins: -1, loses: -1) : friend
    }
    
    func score(overall:Bool = true) -> String {
        let index:String
        let scores:String
        if overall {
            index = "W"
            scores = "\(self.wins.toScore())"
        } else {
            index = "L"
            scores = "\(self.loses.toScore())"
        }
        
        return (scores != "-") ? "\(index): \(scores)"  : ""
    }
}

extension Array where Element == GroupMember {
    func wilsonConfidenceScore(wins: Int, losses: Int, confidence: Double = 0.95) -> Double {
        guard case let n = Double(wins + losses), n != 0 else { return 0.0 }
        
        let z  = 1.96
        let z² = (z * z)
        let p̂  = 1.0 * Double(wins) / n
        
        let lhs = p̂ + z² / (2 * n)
        let rhs = z * sqrt((p̂ * (1 - p̂) + z² / (4 * n)) / n)
        let divisor = 1 + z² / n
        
        let lowerBound = (lhs - rhs) / divisor
        
        return lowerBound
    }
    
    func sortByWilsonRanking() -> [GroupMember] {
        return self.sorted {
            return wilsonConfidenceScore(wins: $0.wins, losses: $0.loses) >
                wilsonConfidenceScore(wins: $1.wins, losses: $1.loses)
        }
    }
}
