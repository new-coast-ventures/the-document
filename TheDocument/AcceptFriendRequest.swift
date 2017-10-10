//
//  AcceptFriendRequest.swift
//  TheDocument
//


import Foundation

final class AcceptFriendRequest: FCMRequest {
    
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String) {
        self.toUID = toUID
        self.title = Constants.Messages.acceptFriendRequestTitle.rawValue
        self.body = String(format: Constants.Messages.acceptFriendRequest.rawValue, currentUser.name)
        super.init(to: "\(FCMPrefix)\(toUID)",  notification: FCMNotification(title: title, body: body ), data:["id":toUID, "type":Constants.Messages.IDS.acceptFriendRequest.rawValue])
    }
}
