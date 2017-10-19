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
    var members:[TDUser]
    var invitees:[TDUser]
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
