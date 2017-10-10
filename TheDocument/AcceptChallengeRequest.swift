//
//  AcceptChallengeRequest.swift
//  TheDocument
//

import Foundation

final class AcceptChallengeRequest: FCMRequest {
    
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName:String) {
        self.toUID = toUID
        self.title = Constants.Messages.acceptChallengeRequestTitle.rawValue
        self.body = String(format: Constants.Messages.acceptChallengeRequest.rawValue, currentUser.name, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeId, "type":Constants.Messages.IDS.acceptChallengeRequest.rawValue])
    }
}
