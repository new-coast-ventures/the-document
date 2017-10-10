//
//  FriendRequestRequest.swift
//  TheDocument
//

import Foundation

final class FriendRequestRequest: FCMRequest {
    
    var title: String
    var body: String
   
    private let toUID: String
    
    init(toUID: String) {
        self.toUID = toUID
        self.title = Constants.Messages.friendRequestTitle.rawValue
        self.body = String(format: Constants.Messages.friendRequest.rawValue, currentUser.name)
        super.init(to: "\(FCMPrefix)\(toUID)", notification: FCMNotification(title: title, body: body ), data:["id":toUID, "type":Constants.Messages.IDS.friendRequest.rawValue])
    }
}
