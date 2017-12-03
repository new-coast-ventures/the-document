//
//  API+Synapse.swift
//  TheDocument
//
//  Created by Scott Kacyn on 12/1/17.
//  Copyright © 2017 Refer To The Document. All rights reserved.
//

import Foundation

public struct SynapseAPIConfiguration {
    let baseURL: URL
}

class SynapseAPIRequest: WebRequest {
    let baseURL: URL
    var parameters: [String : Any]?
    var method: NetworkService.Method = .POST
    var endpoint: String = ""
    var headers: [String: String] { return ["Content-Type": "application/json"] }
}

class SynapseAPIService {
    
    private let conf = SynapseAPIConfiguration(baseURL: URL(string: "https://uat-api.synapsefi.com/v3/")!)
    private let service = NetworkService()
    
    func request(request: SynapseAPIRequest,  success: ((Any?) -> Void)? = nil,  fail: ((Error) -> Void)? = nil) {
        
        let url = request.endpoint.isBlank ? conf.baseURL : conf.baseURL.appendingPathComponent(request.endpoint)
        
        var headers = request.headers
        headers["X-SP-GATEWAY"] = "\(clientId)|\(clientSecret)"
        headers["X-SP-USER"] = "\(oauthKey)|\(fingerprint())"
        headers["X-SP-USER-IP"] = "73.211.78.254"
        
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
    
    func loadFromConfig(key: String, isSandbox: Bool = true) -> String {
        if let path = Bundle.main.path(forResource: "Synapse-Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
            let configKey = isSandbox ? "DEV_\(key)" : key
            return dict[configKey] ?? ""
        }
    }
    
    func fingerprint() -> String {
        return "\(UIDevice.current.identifierForVendor?.uuidString)-AAPL"
    }
    
    func clientId() -> String {
        return loadFromConfig(key: "CLIENT_ID")
    }
    
    func clientSecret() -> String {
        return loadFromConfig(key: "CLIENT_SECRET")
    }
    
    func oid() -> String {
        return "5a21aa91c256c30035896e66" // TEMP
    }
    
    func oauthKey() -> String {
        return "iuda3QJXoILdGQKaAcfi67EkGjMgQKOkEnl6irWC" // TEMP
    }
    
    func refreshToken() -> {
        return "refresh_0u59TjtP2yWrIRYgLxBSZpDzanCEcFGkOldU7veo" // TEMP
    }
}


extension API {
}

/*
 
 let friendRqRequest = FriendRequestRequest(toUID: uid)
 FCMService().request(request: friendRqRequest, success: { (responce) in
 closure?(true)
 }) { (error) in
 closure?(false)
 }
 
 */

