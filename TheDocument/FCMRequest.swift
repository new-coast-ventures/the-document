//
//  FCMRequest.swift
//  TheDocument
//

import Foundation

class FCMRequest: WebRequest {
    
    var parameters: [String : Any]? {
        return simplify()
    }
    var method: NetworkService.Method = .POST
    var endpoint: String = ""
    var headers: [String: String]? { return ["Content-Type": "application/json"]}
    
    let to: String
    let priority:String
    let notification:FCMNotification
    
    let data:[String:String]

    init(to:String, priority:String = "high", notification: FCMNotification, data: [String:String] = [String:String]()) {
        self.to = to
        self.priority = priority
        self.notification = notification
        
        self.data = data
    }
}

extension FCMRequest:FirebaseEncodable {
    func simplify() -> [String : Any] {
        return ["notification" : notification.simplify(), "priority" : priority , "to": to, "data":data, "content_available" : true]
    }
}
