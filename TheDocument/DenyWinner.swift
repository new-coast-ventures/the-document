//
//  DenyWinner.swift
//  TheDocument
//


import Foundation

final class DenyWinner: FCMRequest {
    
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName:String, winnerName: String) {
        self.toUID = toUID
        self.title = Constants.Messages.denyWinnerTitle.rawValue
        self.body = String(format: Constants.Messages.denyWinner.rawValue, winnerName, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeId, "type":Constants.Messages.IDS.denyWinner.rawValue])
    }
}
