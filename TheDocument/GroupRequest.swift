//
//  GroupRequest.swift
//  TheDocument
//

import Foundation

final class GroupRequest: FCMRequest {
    
    var title: String
    var body: String
    
    private let toUID: String
    
    init(toUID: String, groupName: String, groupId: String) {
        self.toUID = toUID
        self.title = Constants.Messages.groupRequestTitle.rawValue
        self.body = String(format: Constants.Messages.groupRequest.rawValue, currentUser.name, groupName)
        super.init(to: "\(FCMPrefix)\(toUID)", notification: FCMNotification(title: title, body: body ), data:["id":groupId, "type":Constants.Messages.IDS.groupRequest.rawValue])
    }
}
