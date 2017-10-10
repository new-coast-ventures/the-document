//
//  RejectChallenge.swift
//  TheDocument
//

import Foundation

final class RejectChallenge: FCMRequest {
    
    var title: String
    var body: String
    
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName: String) {
        self.toUID = toUID
        self.title = Constants.Messages.rejectChallengeTitle.rawValue
        self.body = String(format: Constants.Messages.rejectChallenge.rawValue, currentUser.name, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeId, "type":Constants.Messages.IDS.rejectChallenge.rawValue])
    }
}
