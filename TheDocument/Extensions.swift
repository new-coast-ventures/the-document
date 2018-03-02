//
//  Extensions.swift
//  TheDocument
//


import Foundation
import UIKit

extension CALayer {
    var borderColorFromUIColor: UIColor {
        get {
            return UIColor(cgColor: self.borderColor!)
        } set {
            self.borderColor = newValue.cgColor
        }
    }
    
    func dropShadow() {
        self.shadowColor = UIColor.black.cgColor
        self.shadowOpacity = 0.1
        self.shadowOffset = CGSize(width: 0, height: 1)
        self.shadowRadius = 1
    }
}


extension UIImageView {
    public func imageFromServerURL( _ url: URL?, closure: @escaping ()->Void) {
        
        guard let imageURL = url else {
            //TODO: default image placeholder
            return
        }
        
        URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                //TODO: default image placeholder
                log.error(error!)
                closure()
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
                closure()
            })
            
        }).resume()
    }
}

extension UIView {
    func addBorder(edges: UIRectEdge = UIRectEdge.top, color: UIColor = UIColor(red: 234/255, green: 234/255, blue: 234/255, alpha: 1.0), thickness: CGFloat = 1.0) {
        if (edges.contains(.top) || edges.contains(.all)) {
            let border = UIView()
            border.backgroundColor = color
            border.autoresizingMask = .flexibleBottomMargin
            border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: thickness)
            self.addSubview(border)
        }
    }
}

extension UIViewController {
    
    var activityIndicatorTag: Int { return 77777 }
    
    func startActivityIndicator( style: UIActivityIndicatorViewStyle = .gray, location: CGPoint? = nil) {
        
        let loc = location ?? self.view.center
        
        DispatchQueue.main.async(){
            
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: style)
            
            activityIndicator.tag = self.activityIndicatorTag
            
            activityIndicator.center = loc
            activityIndicator.hidesWhenStopped = true
            
            activityIndicator.startAnimating()
            self.view.addSubview(activityIndicator)
        }
    }
    
    func stopActivityIndicator() {
        
        DispatchQueue.main.async() {
            
            if let activityIndicator = self.view.subviews.filter(
                { $0.tag == self.activityIndicatorTag}).first as? UIActivityIndicatorView {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
        }
    }
}

extension UIViewController {
    func showAlert(title:String = Constants.appName, message: String, closure:((UIAlertAction)->Void)? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: closure)
        
        alertController.addAction(okAction)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        let messageText = NSMutableAttributedString(
            string: message,
            attributes: [
                NSAttributedStringKey.paragraphStyle: paragraphStyle,
                NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: UIFontTextStyle.body),
                NSAttributedStringKey.foregroundColor : UIColor.black
            ]
        )
        
        alertController.setValue(messageText, forKey: "attributedMessage")
        
        DispatchQueue.main.async() {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

protocol ReusableView: class {
    static var defaultReuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {
    static var defaultReuseIdentifier: String {
        return NSStringFromClass(self)
    }
}

extension UITableViewCell: ReusableView {}

extension String {
    
    var isBlank: Bool {
        get {
            let trimmed = trimmingCharacters(in: CharacterSet.whitespaces)
            return trimmed.isEmpty
        }
    }
    
    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) != nil
        } catch {
            return false
        }
    }
    
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    var isValidPassword: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[A-Za-z0-9]{6,}", options: .caseInsensitive)
            return (regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) != nil) ? true : false
        } catch {
            return false
        }
    }
    
    
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func removeWhitespace() -> String {
         return self.replacingOccurrences(of: " ", with: "")
    }
    
    
    func urlFriendly() -> String {
        let charSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890").inverted
        return self.components(separatedBy: charSet).joined()
    }
    
    func toNumeric() -> String {
        return self.replacingOccurrences( of:"[^0-9]", with: "", options: .regularExpression)
    }
    
    func truncate(length: Int, trailing: String = "…") -> String {
        if self.characters.count > length {
            return String(self.characters.prefix(length)) + trailing
        } else {
            return self
        }
    }
    
    //Parses raw score string to a win-lose int tuple
    func parseScore()->(Int,Int) {
        let scores = self.components(separatedBy: "-")
        let wins:Int = Int(scores[0]) ?? 0
        let loses:Int = scores.count > 1 ? Int(scores[1]) ?? 0 : 0
        return (wins, loses)
    }
    
    var data: Data? {
        return self.data(using: String.Encoding.utf8)
    }
   
}

extension UIColor {
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1,height: 1))
        let ctx = UIGraphicsGetCurrentContext()
        self.setFill()
        ctx!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension Array where Element: Equatable {
    
    mutating func removeObject(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

extension Array where Element == TDUser {
    
    mutating func alphaSort() {
        let friends = self as Array<TDUser>
        self = friends.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func alphaSorted() -> [TDUser] {
        let friends = self as Array<TDUser>
        return friends.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}

extension Array where Element == Challenge {
    mutating func completionSort() {
        let challenges = self as Array<Challenge>
        self = challenges.sorted { ($0.completedAt ?? 0) > ($1.completedAt ?? 0) }
    }
    
    func completionSorted() -> [Challenge] {
        let challenges = self as Array<Challenge>
        return challenges.sorted { ($0.completedAt ?? 0) > ($1.completedAt ?? 0) }
    }
}

extension UIImagePickerController {
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.navigationBar.topItem?.rightBarButtonItem?.tintColor = UIColor.black
        self.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
    }
}

extension Bool {
    
    var data : Data {
        
        var b = self
        let p = withUnsafePointer(to: &b) { (p: UnsafePointer<Bool>) -> UnsafeRawPointer in
            return UnsafeRawPointer(p)
        }
        return Data(bytes: p, count: MemoryLayout<Bool>.size)
    }
}

extension Int {
    
    var data : Data {
        
        var i = self
        let p = withUnsafePointer(to: &i, { (p: UnsafePointer<Int>) -> UnsafeRawPointer in
            return UnsafeRawPointer(p)
        })
        
        return Data(bytes: p, count: MemoryLayout<Int>.size)
    }
    
    init(_ bool: Bool) {
        self = bool ? 1 : 0
    }
    
    func toScore() -> String {
        return self > -1 ? "\(self)" : ""
    }
    
    func toUIColor() -> UIColor {
        return UIColor(
            red: CGFloat((self & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((self & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(self & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func toCGColor() -> CGColor {
        return self.toUIColor().cgColor
    }
}

extension UInt {
    
    func toUIColor() -> UIColor {
        return UIColor(
            red: CGFloat((self & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((self & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(self & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func toCGColor() -> CGColor {
        return self.toUIColor().cgColor
    }
}

extension String {
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return boundingBox.height
    }
    
}
