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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    var justLogged = false
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let barBtnAppearance = UIBarButtonItem.appearance()
        barBtnAppearance.tintColor = UIColor.white
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        Instabug.start(withToken: "936e97e6a9d22e84dc652bab777ac20f", invocationEvent: .shake)
        
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        Auth.auth().addStateDidChangeListener(){self.authChanged(auth: $0, authUser: $1)}
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        if !currentUser.isLogged { try? Auth.auth().signOut() }
        
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
        
        let branch: Branch = Branch.getInstance()
        branch.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { params, error in
            if error == nil && params?["+clicked_branch_link"] != nil && params?["userId"] != nil {
                // User opened an invite link; if not yet friends, create the friend request
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
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification launchOptions: [AnyHashable: Any]) -> Void {
//        Branch.getInstance().handlePushNotification(launchOptions)
//    }
    
    func authChanged(auth:Auth, authUser:User?) -> Void {
        guard !justLogged else {  return  }

        if let authenticatedUser = authUser {
            (self.window?.rootViewController as? LoginViewController)?.hideLogin()
        
            Branch.getInstance().setIdentity(authenticatedUser.uid) // Identify user in Branch
            
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
    
    //MARK: UNUserNotificationCenterDelegate (swizzled by Firebase)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
   
        processNotification(title: notification.request.content.title, body: notification.request.content.body, userInfo: notification.request.content.userInfo)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        processNotification(title: response.notification.request.content.title, body: response.notification.request.content.body, userInfo: response.notification.request.content.userInfo)
    }
    
    //MARK: MessageingDelegate

    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
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
        // Messaging.messaging().appDidReceiveMessage(userInfo)
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
    
    private func processNotification(title: String, body: String, userInfo: [AnyHashable: Any]) {
        
        guard let type = userInfo["type"] as? String,  let id = userInfo["id"] as? String else { print("Notification with no type or id. Skipping..."); return}
        
        var eventType = "\(UserEvents.showOverviewTab)"
        
        switch type {
            case Constants.Messages.IDS.friendRequest.rawValue:
                currentUser.getFriends()
                eventType = "\(UserEvents.showFriendsTab)"
            
            case Constants.Messages.IDS.acceptFriendRequest.rawValue:
                if let friendIndex = currentUser.friends.index(where: { $0.id == id}){
                    if currentUser.friends[friendIndex].accepted == false {
                        currentUser.friends[friendIndex].accepted = true
                    }
                    currentUser.getScores()
                } else {
                    currentUser.getFriends()
                }
                
                eventType = "\(UserEvents.showFriendsTab)"
            
            case Constants.Messages.IDS.challengeRequest.rawValue:
                currentUser.getChallenges()
            
            case Constants.Messages.IDS.acceptChallengeRequest.rawValue:
                if let chIndex = currentUser.futureChallenges.index(where: { $0.id == id}){
                    var newCurrentChallenge = currentUser.futureChallenges[chIndex]
                    newCurrentChallenge.accepted = 1
                    currentUser.futureChallenges.remove(at: chIndex)
                    currentUser.currentChallenges.append(newCurrentChallenge)
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                    
                } else {
                    currentUser.getChallenges()
                }
            
            case Constants.Messages.IDS.declareWinner.rawValue:
                
                guard let winnerID = userInfo["winner"] as? String, let declaratorID = userInfo["declarator"] as? String else { currentUser.getChallenges(); return }
                
                if let chIndex = currentUser.currentChallenges.index(where: { $0.id == id}){
                    if currentUser.currentChallenges[chIndex].winner != winnerID {
                        currentUser.currentChallenges[chIndex].winner = winnerID
                        currentUser.currentChallenges[chIndex].declarator = declaratorID
                        //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                    }
                } else {
                    currentUser.getChallenges();
                }
            
            case Constants.Messages.IDS.confirmWinner.rawValue:
                if let chIndex = currentUser.currentChallenges.index(where: { $0.id == id}){
                   currentUser.currentChallenges.remove(at: chIndex)
                   //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                }
                currentUser.getScores()
            
            case Constants.Messages.IDS.denyWinner.rawValue:
                if let chIndex = currentUser.currentChallenges.index(where: { $0.id == id}){
                    currentUser.currentChallenges[chIndex].winner = ""
                    currentUser.currentChallenges[chIndex].declarator = ""
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                }
            
            case Constants.Messages.IDS.rejectChallenge.rawValue:
                if let chIndex = currentUser.futureChallenges.index(where: { $0.id == id}){
                    currentUser.futureChallenges.remove(at: chIndex)
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                }
            
            case Constants.Messages.IDS.cancelChallenge.rawValue:
                if let chIndex = currentUser.currentChallenges.index(where: { $0.id == id}){
                    var newFutureChallenge = currentUser.currentChallenges[chIndex]
                    newFutureChallenge.accepted = 0
                    //currentUser.currentChallenges.remove(at: chIndex)
                    //currentUser.futureChallenges.append(newFutureChallenge)
                    //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.challengesRefresh)"), object: nil)
                } else {
                    currentUser.getChallenges()
                }
            case Constants.Messages.IDS.groupRequest.rawValue:
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.groupsRefresh)"), object: nil)
                eventType = "\(UserEvents.showGroupsTab)"
            default:
                print("Notification with unknown type. Skipping...");
        }
        
        if currentUser.logged {
            TDNotification.show(body, type: .info) { tapped in
                if tapped {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: eventType), object: nil)
                }
            }
            
        } else {
            UserDefaults.standard.set( body, forKey: "wokenNotification")
            UserDefaults.standard.set( eventType, forKey: "wokenNotificationType")
            UserDefaults.standard.synchronize()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.set(nil, forKey: "wokenNotification")
        UserDefaults.standard.set(nil, forKey: "wokenNotificationType")
        UserDefaults.standard.synchronize()
    }
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

