//
//  FCMNotification.swift
//  TheDocument
//

import Foundation

struct FCMNotification {
    let title:String
    let body:String
}

extension FCMNotification:FirebaseEncodable {
    func simplify() -> [String : Any] {
        return ["title":title , "body" : body]
    }
}
