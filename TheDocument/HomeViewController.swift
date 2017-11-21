//
//  HomeViewController.swift
//  TheDocument
//

import UIKit
import Firebase
import FirebaseStorage
import UserNotifications

enum HomeTabs {
    case overview, friends, groups, settings
}

class HomeViewController: UIViewController {
   
    @IBOutlet weak var toolbarHeight: NSLayoutConstraint!
    @IBOutlet weak var toolbarGradient: UIImageView!
    @IBOutlet weak var toolbarContainer: UIView!
    @IBOutlet weak var actionButtonImageView: UIImageView!

    @IBOutlet var menuButtons: [UIButton]!
    @IBOutlet weak var overviewMenuButton: UIButton!
    @IBOutlet weak var friendsMenuButton: UIButton!
    @IBOutlet weak var groupsMenuButton: UIButton!
    @IBOutlet weak var settingsMenuButton: UIButton!
    
    var firstRun = true
    var openedTab: HomeTabs = .overview
    var containerViewController: HomeContainerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Constants.Theme.mainColor
        actionButtonImageView.layer.dropShadow()
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in UserDefaults.standard.setValue("\(Date().timeIntervalSince1970)", forKey: "lastOnline")  })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.toolbarGradient.isHidden = true
                self.toolbarHeight.constant = 0
                self.toolbarContainer.isHidden = true
                self.view.setNeedsLayout()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil, queue: nil) { (notification) in
               DispatchQueue.main.async {
                self.toolbarGradient.isHidden = false
                self.toolbarContainer.isHidden = false
                self.toolbarHeight.constant = 56
                self.view.setNeedsLayout()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "\(UserEvents.showOverviewTab)"), object: nil, queue: nil) { (notification) in  self.showOverviewTapped() }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "\(UserEvents.showFriendsTab)"), object: nil, queue: nil) { (notification) in self.showFriendsTapped() }
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "\(UserEvents.showGroupsTab)"), object: nil, queue: nil) { (notification) in self.showGroupsTapped() }
        
        let color = UIColor.white
        let font = UIFont(name: "OpenSans-Semibold", size: 20)!
        
        let attributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.foregroundColor: color
        ]
        
        UINavigationBar.appearance().titleTextAttributes = attributes
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        API().setLastOnline()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if firstRun {
            fadeOut()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: Constants.shouldSkipIntroKey) {
            // Show welcome intro screens
            self.performSegue(withIdentifier: Constants.introductionVCStoryboardIdentifier, sender: self)
            return
        } else  if !UserDefaults.standard.bool(forKey: Constants.shouldGetPhotoKey) {
            // Set user's profile photo
            self.performSegue(withIdentifier: Constants.getPhotoVCStoryboardIdentifier, sender: self)
            return
        } else {
            // Complete registration for push notifications
            UIApplication.shared.registerForRemoteNotifications()
            self.fadeIn()
        }
        
        if let wokenMessage = UserDefaults.standard.value(forKey: "wokenNotification") as? String {
            UserDefaults.standard.set(nil, forKey: "wokenNotification")
            UserDefaults.standard.synchronize()
            TDNotification.show( wokenMessage , type: .info)
        }
        
        if let wokenMessageType = UserDefaults.standard.value(forKey: "wokenNotificationType") as? String {
            UserDefaults.standard.set(nil, forKey: "wokenNotificationType")
            UserDefaults.standard.synchronize()
            
            switch wokenMessageType {
                case "\(UserEvents.showOverviewTab)":
                    self.somethingNewOn(.overview)
                case "\(UserEvents.showFriendsTab)":
                    self.somethingNewOn(.friends)
                case "\(UserEvents.showGroupsTab)":
                    self.somethingNewOn(.groups)
                default:
                    break;
            }
        }
    }
    
    deinit { NotificationCenter.default.removeObserver(self)  }
    
    @IBAction func showOverviewTapped(_ sender: Any? = nil) {
        openedTab = .overview
        toggleVisibleTab(btn: overviewMenuButton)
        containerViewController.loadChildView(identifier: "embed_overview")
    }
    
    @IBAction func showFriendsTapped(_ sender: Any? = nil) {
        openedTab = .friends
        toggleVisibleTab(btn: friendsMenuButton)
        containerViewController.loadChildView(identifier: "embed_friends")
    }
    
    @IBAction func showGroupsTapped(_ sender: Any? = nil) {
        openedTab = .groups
        toggleVisibleTab(btn: groupsMenuButton)
        containerViewController.loadChildView(identifier: "embed_groups")
    }
    
    @IBAction func showSettingsTapped(_ sender: Any) {
        openedTab = .settings
        toggleVisibleTab(btn: settingsMenuButton)
        containerViewController.loadChildView(identifier: "embed_settings")
    }
    
    func toggleVisibleTab(btn: UIButton) {
        menuButtons.forEach { $0.isSelected = $0 == btn ? true : false }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "home_embed", let vc = segue.destination as? HomeContainerViewController {
            containerViewController = vc
        }
    }
    
    func fadeIn() {
        firstRun = false
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5,delay: 0 ,options: UIViewAnimationOptions.curveEaseIn,animations: { () -> Void in
                self.toolbarContainer.alpha = 1
                self.view.backgroundColor = .white
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func fadeOut() {
        let token = Messaging.messaging().fcmToken
        Messaging.messaging().subscribe(toTopic: "\(FCMPrefix)\(currentUser.uid)")
        self.toolbarContainer.alpha = 0
    }
}

extension HomeViewController {
    
    func somethingNewOn(_ tab:HomeTabs){
        if openedTab != tab {
            DispatchQueue.main.async {
                switch tab {
                    case .overview:
                        self.overviewMenuButton.setImage(UIImage(named:"Menu1New"), for: .normal)
                        self.overviewMenuButton.setImage(UIImage(named:"Menu1NewActive"), for: .selected)
                    case .friends:
                        self.friendsMenuButton.setImage(UIImage(named:"Menu2New"), for: .normal)
                        self.friendsMenuButton.setImage(UIImage(named:"Menu2NewActive"), for: .selected)
                    case .groups:
                        self.groupsMenuButton.setImage(UIImage(named:"Menu3New"), for: .normal)
                        self.groupsMenuButton.setImage(UIImage(named:"Menu3NewActive"), for: .selected)
                    default:
                        break;
                }
                
            }
            
        }
    }
    
    
}
