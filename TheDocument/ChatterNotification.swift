//
//  ChatterNotification.swift
//  TheDocument
//
//  Created by Scott Kacyn on 7/25/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import Foundation

final class ChatterNotification: FCMRequest {
    var title: String
    var body: String
    private let toUID: String
    
    init(toUID: String, challengeId: String, challengeName: String) {
        self.toUID = toUID
        self.title = Constants.Messages.chatterNotificationTitle.rawValue
        self.body = String(format: Constants.Messages.chatterNotificationBody.rawValue, currentUser.name, challengeName)
        super.init(to: "\(FCMPrefix)\(toUID)", notification: FCMNotification(title: title, body: body), data: ["id":challengeId, "type":Constants.Messages.IDS.chatterNotification.rawValue])
    }
}
