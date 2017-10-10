//
//  FirebaseEncodable.swift
//  TheDocument
//

protocol FirebaseEncodable {
    func simplify() -> [String:Any]
}


extension Array where Element == FirebaseEncodable {
    func simplify()->[[String:Any]] {
        var ready = [[String:Any]] ()
        self.forEach{ ready.append($0.simplify()) }
        return ready
    }
}
