//
//  API+Synapse.swift
//  TheDocument
//
//  Created by Scott Kacyn on 12/1/17.
//  Copyright © 2017 Refer To The Document. All rights reserved.
//

import Foundation
import FacebookCore

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
    
    private let service = NetworkService()
    
    func request(request: SynapseAPIRequest, success: ((Any?) -> Void)? = nil, fail: ((Error) -> Void)? = nil) {

        var headers = request.headers
        headers!["X-SP-GATEWAY"] = "\(clientId())|\(clientSecret())"
        headers!["X-SP-USER"] = "\(oauthKey())|\(fingerprint())"
        headers!["X-SP-USER-IP"] = "\(userIpAddress())"
        
        let url = synapseURL(request: request)
        
        let logData: [String: Any] = [
            "url": url.absoluteString,
            "fingerprint": fingerprint(),
            "oauth": oauthKey(),
            "method": request.method
        ]
        
        log.debug("Loading Synapse URL: \(logData)")
        
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
                log.error("statusCode: \(statusCode) fcmError: \(fcmError)")
                fail?(fcmError)
            } else {
                log.error("statusCode: \(statusCode)")
                fail?(NSError(domain: "", code: statusCode, userInfo: ["errorDescription":data ?? Data() ]))
            }
        })
    }
    
    func synapseURL(request: SynapseAPIRequest) -> URL {
        var url = URL(string: loadFromConfig(key: "BASE_URL"))!.appendingPathComponent(request.endpoint)
        
        if let params = request.parameters as? [String: String], request.method == .GET {
            var urlString = url.absoluteString.appending("?")
            params.forEach({ (k, v) in
                urlString = urlString.appending("\(k)=\(v)&")
            })
            
            url = URL(string: urlString)!
        }
        
        return url
    }
    
    func handleError(_ errorJson: Any?) {
        guard let json = errorJson as? [String: Any], let error_code = json["error_code"] as? String else { return }
        
        switch error_code {
        case "110":
            API().authorizeSynapseUser()
        default:
            log.info("ERROR WITH CODE \(error_code): \(json)")
        }
    }
    
    func cancel() {
        service.cancel()
    }
    
    func isLive() -> Bool {
        return !isDev()
    }
    
    func isDev() -> Bool {
        if let path = Bundle.main.path(forResource: "Synapse-Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: Any], let isDev = dict["IS_DEV"] as? Bool {
            return isDev
        }
        return true
    }
    
    func loadFromConfig(key: String) -> String {
        if let path = Bundle.main.path(forResource: "Synapse-Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            let configKey = isDev() ? "DEV_\(key)" : key
            return dict[configKey] as? String ?? ""
        }
        return ""
    }
    
    func userIpAddress() -> String {
        return UserDefaults.standard.string(forKey: "user_last_ip") ?? "::1"
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
            API().pushSynapseUID()
        }
    }
    
    func setWalletId() {
        if let wallet = currentUser.wallet, let id = wallet["_id"] as? String {
            currentUser.walletID = id
            UserDefaults.standard.set(id, forKey: "wallet_id")
            UserDefaults.standard.synchronize()
            API().pushWalletID()
        }
    }
    
    func setPhoneNumber() {
        if let _ = currentUser.phone {
            API().pushPhoneNumber()
        }
    }
    
    func walletId() -> String {
        return UserDefaults.standard.string(forKey: "wallet_id") ?? ""
    }
    
    func userId() -> String {
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
    
    func resetUserKeys() {
        let prefs = UserDefaults.standard
        prefs.removeObject(forKey: "oauth_key")
        prefs.removeObject(forKey: "refresh_token")
        prefs.synchronize()
    }
    
    func loadUser(uid: String, _ closure : ((Bool) -> Void)? = nil) {
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.method = .GET
        request.endpoint = "/users/\(uid)"
        service.request(request: request, success: { (response) in
            if let userRef = response as? [String: Any], let uid = userRef["_id"] as? String, let refreshToken = userRef["refresh_token"] as? String {
                currentUser.synapseData = userRef
                service.setRefreshToken(token: refreshToken)
                service.setUserId(id: uid)
    
                if let phones = userRef["phone_numbers"] as? [String], let phone = phones.first {
                    currentUser.phone = phone
                    API().pushPhoneNumber()
                }
                
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func addKYC(email: String, phone: String, name: String, birthDay: Int, birthMonth: Int, birthYear: Int, addressStreet: String, addressCity: String, addressState: String, addressPostalCode: String, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        
        let payload: [String: Any] = [
            "documents": [[
                "email": email,
                "phone_number": phone.trimmingCharacters(in: .whitespacesAndNewlines),
                "name": name,
                "ip": service.userIpAddress(),
                "entity_type": "NOT_KNOWN",
                "entity_scope": "Not Known",
                "day": birthDay,
                "month": birthMonth,
                "year": birthYear,
                "address_street": addressStreet,
                "address_city": addressCity,
                "address_subdivision": addressState,
                "address_postal_code": addressPostalCode,
                "address_country_code": "US",
                "social_docs": [[
                    "document_value": phone.trimmingCharacters(in: .whitespacesAndNewlines),
                    "document_type": "PHONE_NUMBER_2FA"
                ]]
            ]]
        ]
        
        request.method = .PATCH
        request.endpoint = "/users/\(service.userId())"
        request.parameters = payload
        
        service.request(request: request, success: { (response) in
            if let userRef = response as? [String: Any], let uid = userRef["_id"] as? String, let refreshToken = userRef["refresh_token"] as? String {
                currentUser.synapseData = userRef
                service.setUserId(id: uid)
                service.setRefreshToken(token: refreshToken)
                UserDefaults.standard.set(true, forKey: "is_user_account_verified")
                UserDefaults.standard.synchronize()
            }
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func createSynapseUser(email: String, phone: String, name: String, birthDay: Int, birthMonth: Int, birthYear: Int, addressStreet: String, addressCity: String, addressState: String, addressPostalCode: String, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        let payload: [String: Any] = [
            "logins": [[ "email": email ]],
            "phone_numbers": [ phone.trimmingCharacters(in: .whitespacesAndNewlines) ],
            "legal_names": [ name ],
            "extra": [ "cip_tag": 1, "is_business": false ],
            "documents": [[
                "email": email,
                "phone_number": phone.trimmingCharacters(in: .whitespacesAndNewlines),
                "name": name,
                "ip": service.userIpAddress(),
                "entity_type": "NOT_KNOWN",
                "entity_scope": "Not Known",
                "day": birthDay,
                "month": birthMonth,
                "year": birthYear,
                "address_street": addressStreet,
                "address_city": addressCity,
                "address_subdivision": addressState,
                "address_postal_code": addressPostalCode,
                "address_country_code": "US",
                "social_docs": [[
                    "document_value": phone.trimmingCharacters(in: .whitespacesAndNewlines),
                    "document_type": "PHONE_NUMBER_2FA"
                ]]
            ]]
        ]
        
        request.endpoint = "/users"
        request.parameters = payload
        
        service.request(request: request, success: { (response) in
            if let userRef = response as? [String: Any], let uid = userRef["_id"] as? String, let refreshToken = userRef["refresh_token"] as? String {
                currentUser.synapseData = userRef
                service.setUserId(id: uid)
                service.setRefreshToken(token: refreshToken)
                UserDefaults.standard.set(true, forKey: "is_user_account_verified")
                UserDefaults.standard.synchronize()
            }
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func updatePhoneKYC(documentId: String, phoneNumber: String, phoneDocumentId: String, code: String, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        let payload: [String: Any] = [
            "documents": [[
                "id": documentId,
                "social_docs": [[
                    "id": phoneDocumentId,
                    "document_value": phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    "document_type": "PHONE_NUMBER_2FA",
                    "mfa_answer": code
                ]]
            ]]
        ]
        
        request.method = .PATCH
        request.endpoint = "/users/\(service.userId())"
        request.parameters = payload
        
        service.request(request: request, success: { (response) in
            if let userRef = response as? [String: Any], let uid = userRef["_id"] as? String, let refreshToken = userRef["refresh_token"] as? String {
                currentUser.synapseData = userRef
                service.setUserId(id: uid)
                service.setRefreshToken(token: refreshToken)
                UserDefaults.standard.set(true, forKey: "is_user_account_verified")
                UserDefaults.standard.synchronize()
            }
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func requestMFA(_ closure : ((Bool) -> Void)? = nil) {
        
        guard let phone = currentUser.phone else { closure?(false); return }

        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/oauth/\(service.userId())"
        request.parameters = [
            "refresh_token": service.refreshToken(),
            "phone_number": phone.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            guard let json = response as? [String: Any], let error_code = json["error_code"] as? String, error_code == "10" else { closure?(false); return }
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func verifyMFA(pin: String, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/oauth/\(service.userId())"
        request.parameters = [
            "refresh_token": service.refreshToken(),
            "validation_pin": pin
        ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            if let authRef = response as? [String: Any], let oauthKey = authRef["oauth_key"] as? String, let refreshToken = authRef["refresh_token"] as? String {
                service.setOauthKey(key: oauthKey)
                service.setRefreshToken(token: refreshToken)
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            log.error(error)
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
                closure?(true)
            } else {
                guard let json = response as? [String: Any], let error_code = json["error_code"] as? String, error_code == "10" else { log.debug("AUTH FAIL"); return }
            
                appDelegate.presentMFAViewController()
                closure?(false)
            }
        }) { (error) in
            log.error(error)
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
                var bankNodes: [[String: Any]] = []
                for (_, node) in nodes.enumerated() {
                    guard let nodeInfo = node["info"] as? [String: Any], let classInfo = nodeInfo["class"] as? String, let type = nodeInfo["type"] as? String else { continue }
                    if (classInfo == "CHECKING" && type == "PERSONAL") {
                        bankNodes.append(node)
                    }
                }
                currentUser.nodes = bankNodes
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            log.error(error)
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
                    service.setWalletId()
                    closure?(true)
                } else {
                    self.createWallet() { closure?($0) }
                }
            } else {
                closure?(false)
            }
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func getCurrentWalletBalance() -> Double {
        
        guard let wallet = currentUser.wallet, let info = wallet["info"] as? [String: Any], let balance = info["balance"] as? [String: Any], let amount = balance["amount"] as? Double else { return 0.00 }
        
        let fundsHeld = UserDefaults.standard.double(forKey: "fundsHeld")
        print("Funds Held: \(fundsHeld)")
        print("Amount: \(amount)")
        
        return amount - fundsHeld
    }
    
    func linkBankAccount(bank_id: String, bank_password: String, bank_name: String, _ closure : ((Any) -> Void)? = nil) {
        
        let payload: [String: Any] = [
            "type": "ACH-US",
            "info": [
                "bank_id": bank_id,
                "bank_pw": bank_password,
                "bank_name": bank_name
            ]
        ]
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes"
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(response)
        }) { (error) in
            log.error(error)
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
                service.setWalletId()
                closure?(true)
            } else {
                closure?(false)
            }
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func answerMFA(access_token: String, answer: String, _ closure : ((Any) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes"
        request.parameters = [ "access_token": access_token, "mfa_answer": answer ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            guard let json = response as? [String: Any] else { closure?(false); return }
            if let nodes = json["nodes"] as? [[String: Any]] {
                
                var bankNodes: [[String: Any]] = []
                for (_, node) in nodes.enumerated() {
                    guard let nodeInfo = node["info"] as? [String: Any], let classInfo = nodeInfo["class"] as? String, let type = nodeInfo["type"] as? String else { continue }
                    if (classInfo == "CHECKING" && type == "PERSONAL") {
                        bankNodes.append(node)
                    }
                }
                currentUser.nodes = bankNodes
                closure?(true)
            } else if let error_code = json["error_code"] as? String, let mfa = json["mfa"] as? [String: String], error_code == "10" {
                closure?(mfa)
            } else {
                closure?(false)
            }
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }

    func processTransaction(from: String, to: String, amount: Int, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes/\(from)/trans"
        
        var note = "Challenge Entry Fee"
        if currentUser.walletID == from {
            note = "Challenge Entry Fee"
        } else {
            note = "Challenge Prize"
        }
        
        let payload: [String: Any] = [
            "to": [
                "type": "SUBACCOUNT-US",
                "id": to
            ],
            "amount": [
                "amount": amount,
                "currency": "USD"
            ],
            "extra": [
                "ip": service.userIpAddress(),
                "note": note
            ]
        ]
        
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func withdrawFunds(from: String, to: String, amount: Int, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        let feeNode = service.loadFromConfig(key: "DEPOSIT_NODE")
        request.endpoint = "/users/\(service.userId())/nodes/\(from)/trans"
        
        let payload: [String: Any] = [
            "to": [
                "type": "ACH-US",
                "id": to
            ],
            "amount": [
                "amount": amount,
                "currency": "USD"
            ],
            "fees": [
                [ "fee": 0.05,
                  "note": "Processing Fee",
                  "to": [ "id": feeNode ]
                ]
            ],
            "extra": [
                "ip": service.userIpAddress(),
                "note": "Withdraw to Bank"
            ]
        ]
        
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
    
    func listTransactions(nodeId: String, _ closure : (([[String: Any]]) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.userId())/nodes/\(nodeId)/trans"
        request.method = .GET
        
        SynapseAPIService().request(request: request, success: { (response) in
            if let response = response as? [String: Any], let trans = response["trans"] as? [[String: Any]] {
                closure?(trans)
            } else {
                closure?([])
            }
        }) { (error) in
            log.error(error)
            closure?([])
        }
    }
    
    func depositFunds(from: String, to: String, amount: Int, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        let feeNode = service.loadFromConfig(key: "DEPOSIT_NODE")
        request.endpoint = "/users/\(service.userId())/nodes/\(from)/trans"
        
        var payload: [String: Any] = [
            "to": [
                "type": "SUBACCOUNT-US",
                "id": to
            ],
            "amount": [
                "amount": amount,
                "currency": "USD"
            ],
            "extra": [
                "ip": service.userIpAddress(),
                "note": "Deposit to Wallet"
            ]
        ]
        
        if service.isLive() {
            payload["fees"] = [
                [ "fee": 0.05,
                  "note": "Processing Fee",
                  "to": [ "id": feeNode ]
                ]
            ]
        }
        
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            log.error(error)
            closure?(false)
        }
    }
}

