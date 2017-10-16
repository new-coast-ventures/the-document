//
//  Friend.swift
//  TheDocument
//

import Foundation
import Argo
import Curry
import Runes

struct Friend {
    let id:String
    
    var name:String = ""
    var accepted:Bool = true
    var winsAgainst:Int = 0
    var lossesAgainst:Int = 0
    
    var wins = -1
    var loses = -1
}

extension Friend: Argo.Decodable, FirebaseEncodable {

    init(frId: String, name: String, accepted: Bool, hwins: Int, hlosses: Int) {
        self.id = frId
        self.name = name
        self.accepted = accepted
        self.winsAgainst = hwins
        self.lossesAgainst = hlosses
    }
    
    static func decode(_ json: JSON) -> Decoded<Friend> {
        return curry(Friend.init)
            <^> (json <| "friendId") as Decoded<String>
            <*> (json <| "name")  as Decoded<String>
            <*> ((json <| "accepted" <|> pure(1)) >>- intToBool)
            <*> (json <| "winsAgainst" <|> pure(0) as Decoded<Int>)
            <*> (json <| "lossesAgainst" <|> pure(0) as Decoded<Int>)
    }
    
    func simplify() -> [String : Any] {
        return ["friendId":id, "name": name, "accepted" : accepted]
    }
}

extension Friend {
    static func empty()->Friend {
        return Friend(id: "", name: "", accepted: false, winsAgainst: 0, lossesAgainst:0, wins: -1, loses: -1)
    }
    
    var isEmpty:Bool {
        return id=="" && name==""
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
    
    func avatarImageData() -> Data? {
        return downloadedImages[self.id]
    }
}

extension Array where Element == Friend {
    subscript(id:String)->Friend {
        
        guard id != currentUser.uid else { return currentUser.asFriend() }
        
        if let foundIndex = self.index(where: { $0.id == id }) {
            return self[foundIndex]
        }
        
        return Friend.empty()
    }
    
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
    
    func sortByWilsonRanking() -> [Friend] {
        return self.sorted {
            return wilsonConfidenceScore(wins: $0.wins, losses: $0.loses) >
                wilsonConfidenceScore(wins: $1.wins, losses: $1.loses)
        }
    }
}

extension Friend: Equatable, Hashable {
    static public func ==(lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id
    }
    
    var hashValue: Int {
        get {
            return id.hashValue
        }
    }
}
