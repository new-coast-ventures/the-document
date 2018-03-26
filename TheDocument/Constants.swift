//
//  Constants.swift
//  TheDocument
//

import UIKit
import Firebase

enum Constants {
    static let appName = "The Document"
    
    static let homeVCStoryboardIdentifier = "HomeVC"
    static let introductionVCStoryboardIdentifier = "IntroID"
    static let introductionPageVCStoryboardIdentifier = "IntroPageVC"
    static let getPhotoVCStoryboardIdentifier = "getPhoto"
    static let groupDetailsVCStoryboardIdentifier = "group_show_details"
    static let addGroupStoryboardIdentifier = "add_group"
    static let inviteFriendsStoryboardIdentifier = "invite_friends"
    static let newChallengeStoryboardSegueIdentifier = "new_challenge"
    static let inviteFriendsNewChallengeStoryboardIdentifier = "invite_friends_new_challenge"
    static let challengeDetailsStoryboardIdentifier = "show_challenge_details"
    static let friendDetailsStoryboardIdentifier = "show_friend_details"
    
    static let shouldSkipIntroKey = "shouldWatchIntro"
    static let shouldGetPhotoKey = "getPhoto"
    static let fcmUrl = "https://fcm.googleapis.com/fcm/send"
    static let FCMAuthKey = "AAAAsFk237k:APA91bEEIDMsLhKdio17yFbXbffawxXHJFapyxES4QBKh3n2lR--JfR3TIkxT6hlSwZtma4fqKL4f7RuR63cMUUj7Ag0p9-MTQeQtmJ6MRWiqGXZimRqiyUPyLyrGs9ttR0mUZIXmbLv"
    static let FIRStoragePublicURL = "https://firebasestorage.googleapis.com/v0/b/the-document.appspot.com/o/"
    
    static let futureChallengesTitle = "Pending"
    static let currentChallengesTitle = "Current"
    static let pastChallengesTitle = "Past"
    
    static let resetPasswordTitle = "Reset Password"
    static let resetButtonTitle = "Reset"
    static let resetAlertBody = "Enter your email"
    static let resetAlertConfirmBody = "Are you sure you want to reset your password?"
    static let commonConfirmAlertBody = "Are you sure?"

    static let youTitle = "You"
    
    static let currentFriendsTitle = "Friends"
    static let pendingFriendsTitle = "Pending"
    static let sentFriendsTitle = "Sent"
    static let playButtonTitle = "PLAY"
    static let acceptButtonTitle = "ACCEPT"
    static let resolveButtonTitle = "WINNER"
    
    static let addFriendAlertTitle = "Add Friend"
    static let addFriendAlertBody = "Enter your friend's email"
    static let addFriendAlertPlaceholder = "Email"
    
    static let invitationSuccess = "Invitation successfully sent!"
    static let inviteToGroupButtonTitle = "INVITE TO GROUP"
    static let inviteToChallengeButtonTitle = "INVITE TO CHALLENGE"
    
    static let challengeConfirmWinnerAlertTitle = "Confirm Winner"
    static let challengeConfirmWinnerTitle = "CONFIRM WINNER"
    static let challengeDeclareWinnerAlertTitle = "Declare Winner"
    static let challengeDeclareWinnerTitle = "DECLARE WINNER"
    static let challengeDetailsTitle = "Challenge Details..."
    static let challengeDenyWinnerAlertTitle = "Deny Winner"
    static let challengeDidWinQuestion = "Did %@ win the challenge?\n "
    static let challengeRejectTitle = "Reject Challenge"
    static let challengeCancelTitle = "Cancel Challenge"
    static let challengeRematch = "Request Rematch"
    
    static let friendRequestRejectTitle = "Reject Request"
    
    static let leaderboardTitle = "Leaderboard"
    
    static let addFriendMailSubject = "An invitation from TheDocument"
    
    static let appLink = "http://theDocument/"
    
    static let cropSquareSide:CGFloat = 500.0
    
    static let deleteTitle = "Delete"
    static let leaveTitle = "Leave"
    static let rejectTitle = "Reject"
    
    static let settingsChangedTitle = "Settings have been successfully saved."
    
    static let zeroRecordsData = [
        "GroupsTableViewController" : [
            "offset": CGFloat(62.0),
            "title" : "No Groups",
            "subtitle" : "You aren't part of any groups yet. Get started by creating your first group now!",
            "buttonTitle" : "CREATE GROUP"
        ] ,
        "OverviewTableViewController" : [
            "offset": CGFloat(60.0),
            "title" : "Invite Your Friends" ,
            "subtitle" : "It's not fun challenging yourself. Invite your friends to join in on the action.",
            "buttonTitle" : "ADD FRIENDS"
        ] ,
        "FriendsTableViewController" : [
            "offset": CGFloat(45.0),
            "title" : "Invite Your Friends" ,
            "subtitle" : "It's not fun challenging yourself. Invite your friends to join in on the action.",
            "buttonTitle" : "ADD FRIENDS"
        ] ,
        "WalletTableViewController" : [
            "offset": CGFloat(60.0),
            "title" : "No Wallet" ,
            "subtitle" : "You haven't linked a bank, yet. Setup your wallet to enable paid challenges.",
            "buttonTitle" : "SETUP WALLET"
        ]
    ]
    
    enum Errors:String {
        case defaultError = "Something went wrong. Please try again later!"
        case urlFormat = "Wrong url format"
        case emailFormat = "Not a valid email address"
        case inputDataChallenge = "Please enter a challenge name."
        case inputDataLogin = "The email or password entered is incorrect."
        case inputDataRegister = "Oh snap! Change the item/s below and try submitting again: "
        case inputDataRegisterName = "• Enter your name"
        case inputDataRegisterPostcode = "• Enter a valid US Postal Code"
        case inputDataRegisterEmail = "• Enter a valid email"
        case inputDataRegisterEmailExists = "• This email is already in use"
        case invalidEmail = "Invalid email format"
        case imageSelect = "Please take a photo or choose one from your library"
        case groupCreate = "Please fill out all the fields and set a photo!"
        case passwordRequirements = "Your password must be at least 6 characters and may only contain letters and numbers"
        case winnerNotSelected = "Please select a winner!"
        case groupDoesNotExist = "This group does not exist"
        case inputGroupName = "• Enter group's name"
        case inputGroupDesc = "• Enter group's description"
        case inputGroupImage = "• Choose group's image"
    }
    
    enum Theme {

        // -----------------
        // Colors
        // -----------------
        
        // Primary Orange #F68D23; RGB(246,141,35)
        static let mainColor = UIColor(red: 246/255, green: 141/255, blue: 35/255,  alpha: 1.0)
        static let grayColor = UIColor(red: 221/255, green: 225/255, blue: 226/255, alpha: 1.0)
        
        static let authButtonNormalBorderColor = UIColor(red: 187/255, green: 197/255, blue: 199/255, alpha: 1.0)
        static let authButtonNormalBGColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        static let authButtonNormalTextColor = UIColor(red: 187/255, green: 197/255, blue: 199/255, alpha: 1.0)
        
        static let authButtonSelectedBorderColor = UIColor(red: 5/255, green: 32/255, blue: 73/255, alpha: 1.0)
        static let authButtonSelectedBGColor = UIColor(red: 5/255, green: 32/255, blue: 73/255, alpha: 1.0)
        static let authButtonSelectedTextColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        
        static let buttonBGColor = UIColor.init(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        static let deleteButtonBGColor = UIColor.init(red: 255.0/255.0, green: 84.0/255.0, blue: 85.0/255.0, alpha: 1.0)
        
        static let separatorColor = UIColor.init(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)
        
        static let tabButtonTextColor = UIColor.init(red: 139.0/255.0, green: 153.0/255.0, blue: 159.0/255.0, alpha: 1.0)
        static let tabButtonSelectesTextColor = UIColor(red: 246/255, green: 141/255, blue: 35/255, alpha: 1.0)
        static let tabButtonFontSize:CGFloat = 14.0
        static let tabButtonFontName = "OpenSans-Bold"
        
        static let notificationTitleColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        static let notificationBGColor = UIColor(red: 5/255, green: 32/255, blue: 73/255, alpha: 1.0)
        static let errorNotificationTitleColor = UIColor.init(red: 255.0/255.0, green: 84.0/255.0, blue: 85.0/255.0, alpha: 1.0)
    }
    
    enum Messages:String {
        
        enum IDS:String {
            case friendRequest = "fr"
            case acceptFriendRequest = "af"
            case challengeRequest = "cr"
            case acceptChallengeRequest = "ac"
            case declareWinner = "dw"
            case confirmWinner = "cw"
            case denyWinner = "dy"
            case rejectChallenge = "rc"
            case denyChallenge = "dc"
            case cancelChallenge = "cc"
            case groupRequest = "gr"
            case chatterNotification = "cn"
        }
        
        case resetPasswordSuccess = "You password reset request was received. We will send you an email shortly with instructions."
        case savePhotoSuccess = "Your image has been saved to your photos."
        
        case friendRequestTitle = "Friend Request"
        case friendRequest = "%@ has requested to be your friend on The Document"
        
        case acceptFriendRequestTitle = "New Friend"
        case acceptFriendRequest = "%@ accepted your friend request on The Document"
        
        case challengeRequestTitle = "New Challenge"
        case challengeRequest = "%@ has sent you a challenge, %@"
       
        case acceptChallengeRequestTitle = "Challenge Accepted"
        case acceptChallengeRequest = "%@ has accepted your challenge, %@"
        
        case chatterNotificationTitle = "New Chatter Message"
        case chatterNotificationBody = "%@ sent some chatter in %@"
        
        case declareWinnerTitle = "Winner Declared"
        case declareWinner = "%@ has been declared winner of the challenge, %@"
        
        case confirmWinnerTitle = "Winner Confirmed"
        case confirmWinner = "%@ has been confirmed winner of the challenge, %@"
        
        case denyWinnerTitle = "Winner Denied"
        case denyWinner = "%@ has been denied winner of the challenge, %@"
        
        case rejectChallengeTitle = "Challenge Rejected"
        case rejectChallenge = "%@ has rejected the challenge, %@"
        
        case cancelChallengeTitle = "Challenge Canceled"
        case cancelChallenge = "%@ has canceled the challenge, %@"
        
        case groupRequestTitle = "Group Invitation"
        case groupRequest = "%@ invited you to group, %@"
    }
    
    enum Templates:String {
        case inviteTemplateName = "invite"
        case registrationTemplateName = "register"
        
        enum Keywords:String {
            case userName = "{#user_name#}"
            case invitorName = "{#invitor_name#}"
            case invitedName = "{#invited_name#}"
            case appLink = "{#app_link#}"
        }
    }
}

public func UIColorFromHex(_ hexValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((hexValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((hexValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(hexValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size
    
    let widthRatio  = targetSize.width  / image.size.width
    let heightRatio = targetSize.height / image.size.height
    
    
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
    }
    
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

func generateRandomString( _ length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}

func imagePickerVC(camera:Bool, delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = delegate
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) && camera {
        picker.sourceType = .camera
    } else {
        picker.sourceType = .photoLibrary
        picker.navigationBar.isTranslucent = false
        picker.navigationBar.barTintColor = Constants.Theme.mainColor
        picker.navigationBar.tintColor = .white
        picker.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor : UIColor.white ]
    }

    return picker
}

import Argo

func intToBool(int:Int) -> Decoded<Bool> {
    return decode(int == 1)
}


