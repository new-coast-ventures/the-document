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
}

//extension Group: Decodable, FirebaseEncodable {
//    static func decode(_ json: JSON) -> Decoded<Group> {
//        return curry(Group.init)
//        <^> json <| "id"
//        <*> json <| "name"
//        <*> json <| "admin"
//        <*> (json <|| "members" <|> pure([String]()))
//    }
//    
//    func simplify() -> [String : Any] {
//        return ["id":id, "name":name, "admin":admin, "members":members]
//    }
//}

extension Group {
    static func empty()->Group {
        return Group(id: "", name: "", uid: "", state: .own, members: [])
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
    
    var wins = -1
    var loses = -1
    var hWins = -1
    var hLoses = -1
    
    init(id: String, name: String){
        self.id = id
        self.name = name
        
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
