//
//  ConfirmWinner.swift
//  TheDocument
//


import Foundation

final class ConfirmWinner: FCMRequest {
    
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName:String, winnerName: String) {
        self.toUID = toUID
        self.title = Constants.Messages.confirmWinnerTitle.rawValue
        self.body = String(format: Constants.Messages.confirmWinner.rawValue, winnerName, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeId, "type":Constants.Messages.IDS.confirmWinner.rawValue])
    }
}
