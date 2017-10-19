//
//  AppDelegate.swift
//  TheDocument
//


import UIKit
import UserNotifications
import Firebase
import FirebaseAuth
import Instabug
import Branch

var appDelegate = UIApplication.shared.delegate as! AppDelegate
var currentUser = TDUser()
var homeVC:HomeViewController? {
    return appDelegate.window?.rootViewController as? HomeViewController
}

let gcmMessageIDKey = "gcm.message_id"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var justLogged = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let barBtnAppearance = UIBarButtonItem.appearance()
        barBtnAppearance.tintColor = UIColor.white
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        Instabug.start(withToken: "936e97e6a9d22e84dc652bab777ac20f", invocationEvent: .shake)
        
        FirebaseApp.configure()
        
        Database.database().isPersistenceEnabled = true
        
        Auth.auth().addStateDidChangeListener() { self.authChanged(auth: $0, authUser: $1) }
        
        if !currentUser.isLogged { try? Auth.auth().signOut() }
        
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        // [END set_messaging_delegate]
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        // [END register_for_notifications]
        
        let branch: Branch = Branch.getInstance()
        branch.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { params, error in
            if error == nil && params?["+clicked_branch_link"] != nil && params?["userId"] != nil {
                // TDUser opened an invite link; if not yet friends, create the friend request
                let userId = params?["userId"] as! String
                let userName = params?["userName"] as? String ?? ""
                
                API().getInvitation(from: userId, name: userName)
            }
        })
        
        return true
    }
    
    // Respond to URI scheme links
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().handleDeepLink(url);
        
        // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
        return true
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity)
        
        return true
    }
    
    func authChanged(auth: Auth, authUser: User?) -> Void {
        guard !justLogged else {  return  }

        if let authenticatedUser = authUser {
            (self.window?.rootViewController as? LoginViewController)?.hideLogin()
            Branch.getInstance().setIdentity(authenticatedUser.uid)
            currentUser = TDUser(uid: authenticatedUser.uid, email: authenticatedUser.email!)
            currentUser.startup { self.login(success: $0) }
        } else {
            (self.window?.rootViewController as? LoginViewController)?.showLogin()
        }
    }
   
    func login(success: Bool) {
        if success {
            self.showHome()
        } else {
            (self.window?.rootViewController as? LoginViewController)?.showLogin()
        }
    }
    
    private func showHome() {
        currentUser.isLogged = true
        DispatchQueue.main.async {
            self.window?.rootViewController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: Constants.homeVCStoryboardIdentifier)
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        UserDefaults.standard.set(nil, forKey: "wokenNotification")
        UserDefaults.standard.set(nil, forKey: "wokenNotificationType")
        UserDefaults.standard.synchronize()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

//MARK: Remote resources

var downloadedImages = [String:Data]()

extension AppDelegate {
    func downloadImageFor(id:String, section:String, closure: ((Bool)->Void)? = nil) {
        guard downloadedImages["\(id)"] == nil else { closure?(true); return }
        guard let imageURL = URL(string: "\(Constants.FIRStoragePublicURL)\(section)%2F\(id)?alt=media") else { closure?(false); return }
        
        URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) -> Void in
            
            guard let imgData = data, error == nil else {
                print(error?.localizedDescription ?? "Error loading image \(imageURL)")
                closure?(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if statusCode != 200 {
                    print("Got status code ", statusCode)
                    closure?(false)
                    return
                }
            }
            
            if (id == "-Kw7Hx5KE6SoFZFGsSWJ") {
                print("Setting image data")
                print("Data: ", data.debugDescription)
                print("Response: ", response.debugDescription)
                print("Error: ", error.debugDescription)
            }
            
            downloadedImages["\(id)"] = imgData
            closure?(true)
        }).resume()
    }
}

