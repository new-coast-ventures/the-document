//
//  TDNotification.swift
//  TheDocument
//

import Foundation
import UIKit

enum TDNotificationType {
    case info, error
}

class TDNotification {
    
    static func show(_ message: String?, title: String? = nil, type: TDNotificationType, fromView: UIView? = (UIApplication.shared.delegate as! AppDelegate).window, position: ToastPosition = .top, duration: TimeInterval = 3.0, completion: ((_ didTap: Bool) -> Void)? = nil) {
        
        guard let message = message, let view = fromView else { return }
        
        let style = TDNotificationStyle(type: type)
        let toaster = {
            view.makeToast(message, duration: duration, position: position, title: title, image: nil, style: style, completion: completion)
        }
        
        if !Thread.isMainThread {
            DispatchQueue.main.async { () -> Void in
                toaster()
            }
        } else {
            toaster()
        }
    }
    
    static func show(_ someError: Error?) {
        guard let error = someError as NSError? else { return }
        var message = Constants.Errors.defaultError.rawValue
        
        if let msg = error.userInfo["reason"] {
            message = msg as! String
        } else {
            message = error.description
        }
        
        TDNotification.show(message, type: .error)
    }
    
    static func clearAll(_ containerView: UIView? = (UIApplication.shared.delegate as! AppDelegate).window){
        DispatchQueue.main.async { () -> Void in
            for view in containerView?.subviews ?? [] {
                if let _ = objc_getAssociatedObject(view, &ToastKeys.Timer) as? Timer{
                    containerView?.hideToast(view)
                }
            }
        }
    }
}

open class TDNotificationStyle: ToastStyle {
    
    var type: TDNotificationType = .info
    
    init(type: TDNotificationType) {
        self.type = type
    }
    
    override open var titleColor: UIColor {
        get {
            switch type {
            case .info:
                return Constants.Theme.notificationTitleColor
            default:
                return Constants.Theme.errorNotificationTitleColor
            }
        }
        
        set { }
    }
    
    
    override open var messageAlignment: NSTextAlignment {
        get {
            return NSTextAlignment.center
        }
        
        set { }
    }
    
    override open var titleAlignment: NSTextAlignment {
        get {
            return NSTextAlignment.center
        }
        
        set { }
    }
    
    override open var topMargin: CGFloat {
        get {
            return 54.0
        }
        
        set { }
    }
    
    override open var messageColor: UIColor { get { return self.titleColor } set { } }
    override open var backgroundColor: UIColor { get { return Constants.Theme.notificationBGColor } set { } }
    override open var titleFont: UIFont { get { return UIFont(name: "OpenSans", size: 13.0)!  } set { } }
    override open var messageFont: UIFont{ get { return UIFont(name: "OpenSans-Bold", size: 13.0)! } set { } }
    override open var imageSize: CGSize { get { return CGSize(width: 26.0, height: 23.0) } set { } }
}
