//
//  ChallengeRequest.swift
//  TheDocument
//


import Foundation

final class ChallengeRequest: FCMRequest {
    
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String,challengeId:String, challengeName:String) {
        self.toUID = toUID
        self.title = Constants.Messages.challengeRequestTitle.rawValue
        self.body = String(format: Constants.Messages.challengeRequest.rawValue, currentUser.name, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":challengeName, "type":Constants.Messages.IDS.challengeRequest.rawValue])
    }
}
