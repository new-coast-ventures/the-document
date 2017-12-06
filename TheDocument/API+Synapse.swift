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
        
        let url = request.endpoint.isBlank ? conf.baseURL : conf.baseURL.appendingPathComponent(request.endpoint)
        
        var headers = request.headers
        headers!["X-SP-GATEWAY"] = "\(clientId())|\(clientSecret())"
        headers!["X-SP-USER"] = "\(oauthKey())|\(fingerprint())"
        headers!["X-SP-USER-IP"] = "\(userIpAddress())"

        service.request(url: url, method: request.method, params: request.parameters, headers: headers, success: { data in
            var json: Any? = nil
            if let data = data {
                json = try? JSONSerialization.jsonObject(with: data, options: [])
            }
            success?(json)
            
        }, failure: { data, error, statusCode in
            
            var json: Any? = nil
            if let data = data {
                json = try? JSONSerialization.jsonObject(with: data, options: [])
                print("JSON \(json)")
            }

            if let fcmError = error  {
                print("Error \(fcmError)")
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
        return ""
    }
    
    func userIpAddress() -> String {
        return "::1" // TEMP
    }
    
    func fingerprint() -> String {
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            return "\(uuid)-AAPL"
        } else {
            return "-AAPL"
        }
    }
    
    func clientId() -> String {
        return loadFromConfig(key: "CLIENT_ID")
    }
    
    func clientSecret() -> String {
        return loadFromConfig(key: "CLIENT_SECRET")
    }
    
    func oid() -> String {
        return "" // "5a21aa91c256c30035896e66" // TEMP - currentUser.oid
    }
    
    func oauthKey() -> String {
        return "" // oauth_Z7m0z1jwFhbW38ysTGLiaHIAotCkRJcNq2d4Kxf0: TEMP
    }
    
    func setRefreshToken(token: String) {
        //try Locksmith.saveData(["refresh_token": token], forUserAccount: oid())
    }
    
    func refreshToken() -> String {
        //let dictionary = Locksmith.loadDataForUserAccount(oid())
        //let token = dictionary["refresh_token"] as? String ?? ""
        return "refresh_Ml8kGRpP9wzqceDOKJ7FS4NLi1g06vmrfVWYtZdh" // refresh_0u59TjtP2yWrIRYgLxBSZpDzanCEcFGkOldU7veo"
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
            "extra": [ "cip_tag": 1, "is_business": false ]
        ]
        
        request.endpoint = "/users"
        request.parameters = payload
        
        service.request(request: request, success: { (response) in
            if let userRef = response as? [String: Any], let _id = userRef["_id"] as? String, let refresh_token = userRef["refresh_token"] as? String {
                service.setRefreshToken(token: refresh_token)
                print("Responded with id: \(_id), refresh token: \(service.refreshToken())")
            }
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func addKYCInfo(_ closure : ((Bool) -> Void)? = nil) {
        let payload = [
            "documents": [
                "email": currentUser.email,
                "phone_number": currentUser.phone!,
                "name": currentUser.name,
                "entity_type": "unknown",
                "entity_scope": "unknown",
                "day": "1", //currentUser.birthDay,
                "month": "9", //currentUser.birthMonth,
                "year": "1987", //currentUser.birthYear,
                "address_street": "123 Main Street", //currentUser.address.street
                "address_city": "Chicago", //currentUser.address.city
                "address_subdivision": "IL", //currentUser.address.state
                "address_postal_code": currentUser.postcode!, //currentUser.address.postcode
                "address_country_code": "US", // only allow US members for now
                "social_docs": [
                    "document_value": "https://www.facebook.com/valid", // currentUser.fbAccessToken,
                    "document_type": "FACEBOOK"
                ]
            ]
        ]
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.oid())"
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
        request.endpoint = "/oauth/\(service.oid())"
        request.parameters = [ "refresh_token": service.refreshToken() ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func linkBankAccount(bank_id: String, bank_password: String, bank_name: String, _ closure : ((Bool) -> Void)? = nil) {
        
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
        request.endpoint = "/users/\(service.oid())/nodes"
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
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
        request.endpoint = "/users/\(service.oid())/nodes"
        request.parameters = payload
        
        SynapseAPIService().request(request: request, success: { (response) in
//            if let http_code = response["http_code"] as? String, http_code == "202", let mfa_dict = response["mfa"] as? [String: Any]  {
//                self.mfaVC = mfaViewController(mfa: mfa_dict)
//                self.present(self.mfaVC, animated: true, completion: nil)
//            }
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func answerMFA(access_token: String, answer: String, _ closure : ((Bool) -> Void)? = nil) {
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.oid())/nodes"
        request.parameters = [ "access_token": access_token, "mfa_answer": answer ]
        
        SynapseAPIService().request(request: request, success: { (response) in
            closure?(true)
        }) { (error) in
            print(error.localizedDescription)
            closure?(false)
        }
    }
    
    func transferFunds(from: String, to: String, amount: Int, _ closure : ((Bool) -> Void)? = nil) {
        
        let service = SynapseAPIService()
        let request = SynapseAPIRequest()
        request.endpoint = "/users/\(service.oid())/nodes/\(from)"
        
        let payload: [String: Any] = [
            "to": [
                "type": "SUBACCOUNT-US",
                "id": to
            ],
            "amount": [
                "amount": amount,
                "currency": "USD" // only support USD
            ],
            "fees": [
                [ "fee": -0.05,
                  "note": "Facilitator Fee",
                  "to": "<ID OF FIDUCIARY ACCOUNT>"
                ]
            ],
            "extra": [
                "ip": service.userIpAddress(),
                "note": "ACH to Wallet"
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

