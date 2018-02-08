//
//  TDCache.swift
//  TheDocument
//

import Foundation

protocol Cacherable: class {
    
    var key: String { get set }
    var value: Data? { get }
    
    init()
    
    func store(_ value: Any?)
}

extension Cacherable {
    
    init(_ dkey: String) {
        self.init()
        self.key = dkey
    }
}

class TDCache {
    
    enum CacheType { case defaults, disk }
    
    var data: Data? {
        return cacher.value
    }
    
    var bool: Bool? {
        return cacher.value?.bool ?? false
    }
    
    var string: String? {
        if let v = cacher.value {
            return v.string
        }
        return nil
    }
    
    var int: Int? {
        return cacher.value?.int
    }
    
    var json: Any? {
        guard let value = cacher.value else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: value, options: .allowFragments)
        }
        catch {
            return nil
        }
    }
    
    private var cacher: Cacherable
    
    init(_ key: String, type: CacheType = .defaults) {
        cacher = type == .defaults ? DefaultsProxy(key) : DiskProxy(key)
    }
    
    func setValue(_ value: Any?){
        cacher.store(value)
    }
}

class TDDiskCache: TDCache {
    override init(_ key: String, type: CacheType = .disk) {
        super.init(key, type: .disk)
    }
}

// MARK: - Cachers

class DefaultsProxy: Cacherable {
    
    var key = ""
    
    private let defaults = UserDefaults.standard
    
    required init() { }
    
    var value: Data? {
        return defaults.data(forKey: self.key)
    }
    
    func store(_ value: Any?) {
        if let value = value {
            self.defaults.setValue(toData(value), forKey: self.key)
        }
    }
}

class DiskProxy: Cacherable {
    
    var key = ""
    
    private let diskCacheLiteral = "TDDiskCache_"
    
    required init() { }
    
    var value: Data? {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let readPath = "\(documents)/\(self.diskCacheLiteral)\(key)"
        return (try? Data(contentsOf: URL(fileURLWithPath: readPath)))
    }
    
    func store(_ value: Any?) {
        let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let writePath = documentsDirectoryPath + "/" + self.diskCacheLiteral + key
        if let value = value, let data = toData(value) {
            try? data.write(to: URL(fileURLWithPath: writePath), options: [.atomic])
        } else {
            do {
                let contents: [String] = try FileManager.default.contentsOfDirectory(atPath: documentsDirectoryPath)
                if let index = contents.index(where: { $0.range(of: self.diskCacheLiteral + key) != nil }) {
                    let path = documentsDirectoryPath + "/" + contents[index]
                    try FileManager.default.removeItem(atPath: path)
                }
            } catch {
                log.error(error)
            }
        }
    }
}

func toData(_ v:Any?) -> Data?{
    
    if let int = v as? Int {
        return int.data
    }
    else if let vStr = v as? String {
        return vStr.data
    }
    else if let bool = v as? Bool {
        return bool.data
    }
    else if let data = v as? Data {
        return data
    }
    
    return nil
}
