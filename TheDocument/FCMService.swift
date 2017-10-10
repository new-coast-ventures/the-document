//
//  FCMService.swift
//  TheDocument
//

import Foundation


let FCMPrefix = "/topics/CH"

public struct FCMConfiguration {
    let baseURL: URL
}

class FCMService {
    
    private let conf = FCMConfiguration(baseURL: URL(string: Constants.fcmUrl)!)
    private let service = NetworkService()
    
    func request(request: FCMRequest,  success: ((Any?) -> Void)? = nil,  fail: ((Error) -> Void)? = nil) {
        
        let url = request.endpoint.isBlank ? conf.baseURL : conf.baseURL.appendingPathComponent(request.endpoint)
        
        var headers = request.headers
        headers?["Authorization"] = "key=\(Constants.FCMAuthKey)"
        
        service.request(url: url, method: request.method, params: request.parameters, headers: headers, success: { data in
            var json: Any? = nil
            if let data = data {
                json = try? JSONSerialization.jsonObject(with: data, options: [])
            }
            success?(json)
            
        }, failure: { data, error, statusCode in
            
            if let fcmError = error  {
                fail?(fcmError)
            } else {
                fail?(NSError(domain: "", code: statusCode, userInfo: ["errorDescription":data ?? Data() ]))
            }
            
        })
    }
    
    func cancel() {
        service.cancel()
    }
}
