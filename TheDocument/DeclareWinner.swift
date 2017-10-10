//
//  DeclareWinner.swift
//  TheDocument
//

import Foundation

final class DeclareWinner: FCMRequest {
    
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName:String, winnerName: String, winnerID: String, declaratorID: String) {
        self.toUID = toUID
        self.title = Constants.Messages.declareWinnerTitle.rawValue
        self.body = String(format: Constants.Messages.declareWinner.rawValue, winnerName, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeId, "type":Constants.Messages.IDS.declareWinner.rawValue, "winner":winnerID, "declarator": declaratorID])
    }
}
