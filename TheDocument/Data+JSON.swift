//
//  Data+JSON.swift
//  TheDocument
//


import Foundation

extension Data {
    
    
    var bool: Bool {
        let ptr = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        let buffer = UnsafeMutableBufferPointer(start: ptr, count: count)
        _ = self.copyBytes(to: buffer)

        return ptr.pointee
    }
    
    var int: Int {
        let ptr = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        let buffer = UnsafeMutableBufferPointer(start: ptr, count: count)
        _ = self.copyBytes(to: buffer)
        
        return ptr.pointee
    }
    
    
    var string: String {
        if let s = String(data: self, encoding: String.Encoding.utf8) {
            return s
        }
        return ""
    }
    
    var json:[String : Any]? {
        var ret: [String : Any]?
        do {
            ret = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.mutableLeaves)  as? [String : Any]
        }
        catch {
            ret = nil
        }
        return ret
    }
}
