//
//  NetworkService.swift
//  TheDocument
//

import Foundation

protocol WebRequest {
    var endpoint: String { get }
    var method: NetworkService.Method { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
}

class NetworkService {
    
    private var task: URLSessionDataTask?
    private var successCodes: Range<Int> = 200..<299
    private var failureCodes: Range<Int> = 400..<499
    
    enum Method: String {
        case GET, POST, PATCH, PUT, DELETE
    }
    
    func request(url: URL, method: Method,
                 params: [String: Any]? = nil,
                 headers: [String: String]? = nil,
                 success: ((Data?) -> Void)? = nil,
                 failure: ((_ data: Data?, _ error: Error?, _ responseCode: Int) -> Void)? = nil) {
        
        var request = URLRequest(url: url , cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        if let params = params {
            request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        }
        
        let session = URLSession.shared
        task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { failure?(data,error, 0); return  }
            
            if error != nil || !self.successCodes.contains(statusCode) {
                log.error([data, error])
                failure?(data,error,statusCode)
                return
            }
            
            success?(data)
        })
        
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}
