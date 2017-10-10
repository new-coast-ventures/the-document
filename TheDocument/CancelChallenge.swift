//
//  CancelChallenge.swift
//  TheDocument
//

import Foundation

final class CancelChallenge: FCMRequest {
    
    var title: String
    var body: String
    
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName: String) {
        self.toUID = toUID
        self.title = Constants.Messages.cancelChallengeTitle.rawValue
        self.body = String(format: Constants.Messages.cancelChallenge.rawValue, currentUser.name, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeId, "type":Constants.Messages.IDS.cancelChallenge.rawValue])
    }
}
