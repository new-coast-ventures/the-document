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
    var parameters: [String : Any]? = [:]
    var method: NetworkService.Method = .POST
    var endpoint: String = ""
    var headers: [String: String]? { return ["Content-Type": "application/json"] }

    init() {
    }
}

class SynapseAPIService {
    
    private let conf = SynapseAPIConfiguration(baseURL: URL(string: "https://uat-api.synapsefi.com/v3.1")!)
    private let service = NetworkService()
    
    func request(request: SynapseAPIRequest, success: ((Any?) -> Void)? = nil, fail: ((Error) -> Void)? = nil) {
        
        var url = request.endpoint.isBlank ? conf.baseURL : conf.baseURL.appendingPathComponent(request.endpoint)
        if let params = request.parameters as? [String: String], request.method == .GET {
            var urlString = url.absoluteString.appending("?")
            params.forEach({ (k, v) in
                urlString = urlString.appending("\(k)=\(v)&")
            })
            
            url = URL(string: urlString)!
        }
        
        var headers = request.headers
        headers!["X-SP-GATEWAY"] = "\(clientId())|\(clientSecret())"
        headers!["X-SP-USER"] = "\(oauthKey())|\(fingerprint())"
        headers!["X-SP-USER-IP"] = "\(userIpAddress())"

        print("SYNAPSE REQUEST: \(url.absoluteString)")
        service.request(url: url, method: request.method, params: request.parameters, headers: headers!, success: { data in
            var json: Any? = nil
            if let data = data {
                json = try? JSONSerialization.jsonObject(with: data, options: [])
            }
            success?(json)
            
        }, failure: { data, error, statusCode in
            
            var json: Any? = nil
            if let data = data {
                json = try? JSONSerialization.jsonObject(with: data, options: [])
                self.handleError(json)
            }
            
            if let fcmError = error  {
                print("Error \(fcmError)")
                fail?(fcmError)
            } else {
                fail?(NSError(domain: "", code: statusCode, userInfo: ["errorDescription":data ?? Data() ]))
            }
        })
    }
    
    func handleError(_ errorJson: Any?) {
        guard let json = errorJson as? [String: Any], let error_code = json["error_code"] as? String else { print("Handle error did not return expected result"); return }
        
        switch error_code {
        case "110":
            print("Invalid/expired oauth_key. Reauthorizing user now...")
            API().authorizeSynapseUser()
        default:
            print("Error Code: \(error_code)")
        }
    }
    
    func cancel() {
        service.cancel()
    }
    
    func loadFromConfig(key: String, isSandbox: Bool = true) -> String {
        if let path = Bundle.main.path(forResource: "Synapse-Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: String] {
            let configKey = isSandbox ? "DEV_\(key)" : key
            return dict[configKey] ?? ""
        }
        return ""
    }
    
    func userIpAddress() -> String {
        return "::1" // TEMP
    }
    
    func fingerprint() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            return "\(uuid)-AAPL"
        } else {
            return "0-AAPL"
        }
    }
    
    func clientId() -> String {
        return loadFromConfig(key: "CLIENT_ID")
    }
    
    func clientSecret() -> String {
        return loadFromConfig(key: "CLIENT_SECRET")
    }
    
    func setUserId(id: Any?) {
        if let id = id as? String {
            currentUser.synapseUID = id
            UserDefaults.standard.set(id, forKey: "synapse_uid")
            UserDefaults.standard.synchronize()
        }
    }
    
    func userId() -> String {
        //return currentUser.synapseUID
        return UserDefaults.standard.string(forKey: "synapse_uid") ?? ""
    }
    
    func setOauthKey(key: Any?) {
        if let key = key as? String {
            UserDefaults.standard.set(key, forKey: "oauth_key")
            UserDefaults.standard.synchronize()
        }
    }
    
    func oauthKey() -> String {
        return UserDefaults.standard.string(forKey: "oauth_key") ?? ""
    }
    
    func setRefreshToken(token: Any?) {
        if let token = token as? String {
            UserDefaults.standard.set(token, forKey: "refresh_token")
            UserDefaults.standard.synchronize()
        }
    }
    
    func refreshToken() -> String {
        return UserDefaults.standard.string(forKey: "refresh_token") ?? ""
    }
}

extension API {
    
    func createSynapseUser(email: String, phone: String, name: String, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        
        let payload: [String: Any] = [
            "logins": [[ "email": email ]],
            "phone_numbers": [ phone ],
            "legal_names": [ name ],
            "extra": [ "cip_tag": 1, "is_business": false ],
            "documents": [[
                "email": email,
                "phone_number": phone,
                "name": name,
                "ip": service.userIpAddress(),
                "entity_type": "NOT_KNOWN",
                "entity_scope": "Not Known",
                "day": 1, //currentUser.birthDay,
                "month": 9, //currentUser.birthMonth,
                "year": 1987, //currentUser.birthYear,
                "address_street": "123 Main Street", //currentUser.address.street
                "address_city": "Chicago", //currentUser.address.city
                "address_subdivision": "IL", //currentUser.address.state
                "address_postal_code": currentUser.postcode!, //currentUser.address.postcode
                "address_country_code": "US", // only allow US members for now
                "social_docs": [[
                    "document_value": "https://www.facebook.com/valid", // currentUser.fbAccessToken,
                    "document_type": "FACEBOOK"
                    ]]
                ]]
        ]
        
        request.endpoint = "/users"
        request.parameters = payload
        
        service.request(request: request, success: { (response) in
            if let userRef = response as? [String: Any], let uid = userRef["_id"] as? String, let refreshToken = userRef["refresh_token"] as? String {
                print("Created user: \(userRef)")
                currentUser.synapseData = userRef
                currentUser.synapseUID = uid
                service.setUserId(id: uid)
                service.setRefreshToken(token: refreshToken)
            }
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func addKYCInfo(_ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        
        let payload = [
            "documents": [[
                "email": currentUser.email,
                "phone_number": currentUser.phone!,
                "name": currentUser.name,
                "ip": service.userIpAddress(),
                "entity_type": "NOT_KNOWN",
                "entity_scope": "Not Known",
                "day": 1, //currentUser.birthDay,
                "month": 9, //currentUser.birthMonth,
                "year": 1987, //currentUser.birthYear,
                "address_street": "123 Main Street", //currentUser.address.street
                "address_city": "Chicago", //currentUser.address.city
                "address_subdivision": "IL", //currentUser.address.state
                "address_postal_code": currentUser.postcode!, //currentUser.address.postcode
                "address_country_code": "US", // only allow US members for now
                "social_docs": [[
                    "document_value": "https://www.facebook.com/valid", // currentUser.fbAccessToken,
                    "document_type": "FACEBOOK"
                ]]
            ]]
        ]
        
        request.endpoint = "/users/\(service.userId())"
        request.method = .PUT
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func authorizeSynapseUser(_ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/oauth/\(service.userId())"
        request.parameters = [ "refresh_token": service.refreshToken() ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            if let authRef = response as? [String: Any], let oauthKey = authRef["oauth_key"] as? String, let refreshToken = authRef["refresh_token"] as? String {
                service.setOauthKey(key: oauthKey)
                service.setRefreshToken(token: refreshToken)
            }
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func getLinkedAccounts(_ closure : ((Bool) -> Void)? = nil) {
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes"
        request.parameters = [ "type": "ACH-US" ]
        request.method = .GET

        SynapseAPIService().request(request: request, success: { (response) in
            if let json = response as? [String: Any], let nodes = json["nodes"] as? [[String: Any]] {
                currentUser.nodes = nodes
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            print("Get Linked Accounts Error: \(error.localizedDescription)")
            closure?(false)
        }
    }
    
    func getWallet(_ closure : ((Bool) -> Void)? = nil) {
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        
        request.endpoint = "/users/\(service.userId())/nodes"
        request.parameters = [ "type": "SUBACCOUNT-US" ]
        request.method = .GET
        
        SynapseAPIService().request(request: request, success: { (response) in
            if let json = response as? [String: Any], let nodes = json["nodes"] as? [[String: Any]] {
                currentUser.wallet = nodes.first
                if currentUser.wallet != nil {
                    closure?(true)
                } else {
                    self.createWallet() { closure?($0) }
                }
            } else {
                closure?(false)
            }
        }) { (error) in
            print("Get Wallet Error: \(error.localizedDescription)")
            closure?(false)
        }
    }
    
    func linkBankAccount(bank_id: String, bank_password: String, bank_name: String, _ closure : ((Any) -> Void)? = nil) {
        
        let payload: [String: Any] = [
            "type": "ACH-US",
            "info": [
                "bank_id": "synapse_good",
                "bank_pw": "test1234",
                "bank_name": "fake"
            ]
        ]
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes"
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(response)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func createWallet(_ closure : ((Bool) -> Void)? = nil) {
        
        let payload: [String: Any] = [
            "type": "SUBACCOUNT-US",
            "info": [ "nickname": "My Wallet" ]
        ]
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes"
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            if let json = response as? [String: Any], let nodes = json["nodes"] as? [[String: Any]] {
                currentUser.wallet = nodes.first
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func answerMFA(access_token: String, answer: String, _ closure : ((Bool) -> Void)? = nil) {
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes"
        
        //TEMP FOR TESTING, replace with "answer"
        request.parameters = [ "access_token": access_token, "mfa_answer": "test_answer" ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            if let json = response as? [String: Any], let nodes = json["nodes"] as? [[String: Any]] {
                currentUser.nodes = nodes
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func depositFunds(from: String, to: String, amount: Int, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes/\(from)/trans"
        
        let payload: [String: Any] = [
            "to": [
                "type": "SUBACCOUNT-US",
                "id": to
            ],
            "amount": [
                "amount": amount,
                "currency": "USD"
            ],
            "fees": [
                [ "fee": -0.05,
                  "note": "Facilitator Fee",
                  "to": [ "id": "None" ]
                ]
            ],
            "extra": [
                "ip": service.userIpAddress(),
                "note": "Deposit funds from bank to wallet"
            ]
        ]
        
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
}

