//
//  AppDelegate.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

////"http://89.107.61.153/api/"

import UIKit
import MBProgressHUD
import TwilioVoice
import PushKit
import IQKeyboardManagerSwift
import UserNotifications
import Firebase
import FirebaseMessaging
import FirebaseCore
import FirebaseInstanceID
import NotificationBannerSwift
import TwilioChatClient
import NotificationBannerSwift


protocol PushKitEventDelegate: AnyObject
{
    func credentialsUpdated(credentials: PKPushCredentials) -> Void
    func credentialsInvalidated() -> Void
    func incomingPushReceived(payload: PKPushPayload) -> Void
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) -> Void
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate, MessagingDelegate
{
    
    var timer:Timer?
    var window: UIWindow?
    var deviceIDFCM:String = ""
    let gcmMessageIDKey = "gcm.message_id"
    var stateManager = StateManager.shared
    var pushKitEventDelegate: PushKitEventDelegate?
    var voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
    
    var callManager = CallSessionManager.shared
    var callConManager = CallConnectivityManager.shared
    var backgroundTaskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var updatedPushToken: Data? = Data.init()
    var receivedNotification =  [AnyHashable : Any]()
    
    //creating the notification content
    var content = UNMutableNotificationContent()
    
    //getting the notification trigger
    //it will be called after 5 seconds
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    
    //getting the notification request
    var localNotificationRequest : UNNotificationRequest?
    
    var expiryDate:Date?
    {
        didSet
        {
//            if let endDate = self.expiryDate
//            {
//                let differenceInSeconds = Int(endDate.timeIntervalSince(Date()))
//                print("Setting Timmer for :\(differenceInSeconds)")
//                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(differenceInSeconds), target: self, selector: #selector(getAcessTokensRefreshed), userInfo: nil, repeats: false)
//            }
        }
    }
    
    // MARK:- Implementation
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        NSLog("Twilio Voice Version: %@", TwilioVoice.sdkVersion())
        
        initializePushKit()
        
        registerForPUSHNotifications()
        
        Messaging.messaging().delegate = self
        
        application.registerForRemoteNotifications()
        
        if UserDefaults.standard.integer(forKey: AppConstants.WAIT_TIME_IN_SECONDS) == 0
        {
            UserDefaults.standard.set(0, forKey: AppConstants.WAIT_TIME_IN_SECONDS)
            UserDefaults.standard.synchronize()
        }
        
        let remoteNotif = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? NSDictionary
        
        if remoteNotif != nil
        {
            showAlertControllerWith(messageTitle: "messageTitle", messageBody: "messageBody")
            {
                
            }
        }
        else
        {
            print("Not remote")
        }
        
        self.pushKitEventDelegate = callConManager
        application.applicationIconBadgeNumber = 0;
        
        // Get Contact List for Modify Chat Push Notification
        getContactList()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        let message = url.host?.removingPercentEncoding
        let alertController = UIAlertController(title: "Incoming Message", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alertController.addAction(okAction)
        
        window?.rootViewController?.present(alertController, animated: true, completion: nil)
        
        return true
    }
    
    override init()
    {
        super.init()
        FirebaseApp.configure()
    }
    
    func initializePushKit()
    {
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
    }
    
    // MARK:- Helpers
    
    func handleProgressView(_ value:Bool)
    {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        if var topController = keyWindow?.rootViewController
        {
            while let presentedViewController = topController.presentedViewController
            {
                topController = presentedViewController
            }
            
            if value
            {
                InterfaceManager.shared.showLoader()
            }
            else
            {
                InterfaceManager.shared.hideLoader()
            }
        }
    }
    
    func openConversationView(_ fromparam:String, toparam:String)
    {
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ConvesationViewController") as? ConvesationViewController
        {
            let directionparam = "Inbound"
            controller.selectedChat = HistoryResponseElement(with: toparam, from: fromparam, direction: directionparam)
            controller.isFromPushNotificationPresent = true
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            
            if var topController = keyWindow?.rootViewController
            {
                while let presentedViewController = topController.presentedViewController
                {
                    topController = presentedViewController
                }
                
                // topController should now be your topmost view controller
                
                topController.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func openChatViewWith(channelSID: String, author:String)
    {
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        {
            controller.navigation = .PUSH
            
            controller.channelSID = channelSID
            
            controller.toName = self.findUserNameFor(providerCode: author)
            
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            
            if var topController = keyWindow?.rootViewController
            {
                while let presentedViewController = topController.presentedViewController
                {
                    topController = presentedViewController
                }
                
                // topController should now be your topmost view controller
                
                if topController is UINavigationController
                {
                    (topController as? UINavigationController)?.pushViewController(controller, animated: true)
                }
                else
                {
                    let nav = UINavigationController.init()
                    nav.pushViewController(controller, animated: true)
                }
            }
        }
    }
    
    func showAlertControllerWith(messageTitle:String, messageBody:String, completionHandler: @escaping () -> ())
    {
        let alertController = UIAlertController(title: messageTitle, message: messageBody, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Open", style: UIAlertAction.Style.default, handler:
        { _ in
            
            completionHandler()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.destructive, handler:nil))
        alertController.addAction(okAction)
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        if var topController = keyWindow?.rootViewController
        {
            while let presentedViewController = topController.presentedViewController
            {
                topController = presentedViewController
            }
            
            // topController should now be your topmost view controller
            
            topController.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func showAlertOfNewMessage(_ userInfo:[AnyHashable: Any])
    {
        let tonumber:String = userInfo["tonumber"] as? String ?? ""
        let fromnumber:String = userInfo["fromnumber"] as? String ?? ""
        let module:String = userInfo["module"] as? String ?? "ch"
        
        guard module == "c" else
        {
            return
        }
        
        self.openConversationView(fromnumber, toparam: tonumber)
    }
    
    func syncUserStatusWithWebLoggedInUser(staus:String)
    {
        //            if status in payload is 'Available' or 'Idle' then status will be Online or whatever word you are using for Online
        //            if status in payload is 'Offline' or 'Unavailable' then status will be Online or whatever word you are using for Offline
        //            if status in payload is 'Busy' or 'WrapUp' then status will be Online or whatever word you are using for Busy
        
        switch staus
        {
        case "Offline":
            print("Offline")
            StateManager.shared.currentStatus = .offline
        case "Unavailable":
            print("Unavailable")
            StateManager.shared.currentStatus = .offline
            
        case "Available":
            print("Available")
            StateManager.shared.currentStatus = .online
            
        case "Idle":
            print("Idle")
            StateManager.shared.currentStatus = .online
            
        case "Busy":
            print("Busy")
            StateManager.shared.currentStatus = .busy
            
        case "WrapUp":
            print("WrapUp")
            StateManager.shared.currentStatus = .busy
            
        default:
            print("default")
        }
    }
    
    func logoutUser(handler: @escaping (()->Void))
    {
        if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = self.stateManager.loginViewModel.userProfile?.twillioToken
        {
            handleProgressView(true)
            let myGroup = DispatchGroup()

            myGroup.enter() //for `checkSpeed`
            myGroup.enter() //for `doAnotherAsync`
            
            TwilioVoice.unregister(accessToken: validAccessToken, deviceToken: validDeviceData)
            { (error) in
                NSLog("LOGOUT: Successfully unregister for VoIP push notifications.")
                myGroup.leave()
            }
            
            MessagingManager.sharedManager().logout
            { (success, errorMessage) in
                NSLog("LOGOUT: Successfully unregister for Chat push notifications.")
                myGroup.leave()
            }
            
            myGroup.notify(queue: DispatchQueue.main)
            {
                self.handleProgressView(false)

                UserDefaults.standard.removeObject(forKey: AppConstants.USER_ACCESS_TOKEN)
                UserDefaults.standard.removeObject(forKey: AppConstants.USER_PROFILE_MODEL)
                UserDefaults.standard.removeObject(forKey: "currentStatus")
                UserDefaults.standard.synchronize()
                
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let rootVC = storyboard.instantiateInitialViewController()
                let window = UIApplication.shared.windows.first

                window?.rootViewController = rootVC
                handler()
            }
        }
    }
    
    // MARK:- Access Token
    
    /// Refreshes the twilio access token
    /// and server auth token.
    /// - Parameters:
    ///     - checkExpiryDate: should check for expiry date or not.
    ///     - handler: the completion block.
    
    @objc func getAcessTokensRefreshed(checkExpiryDate :Bool, handler: @escaping (()->Void))
    {
        if checkExpiryDate
        {
            if let validExpDate = self.expiryDate
            {
                let expDate = validExpDate.toLocalTime()
                let currentDate = Date().toLocalTime()
                
                if expDate <= currentDate
                {
                    handleTokensRefresh
                    {
                        handler()
                    }
                }
                else
                {
                    handler()
                }
            }
            else
            {
                handler()
            }
        }
        else
        {
            handleTokensRefresh
            {
                handler()
            }
        }
    }
    
    /// Handles the tokens refresh using DispatchGroup
    /// - Parameters:
    ///     - handler: the completion block.
    
    func handleTokensRefresh(handler: @escaping (()->Void))
    {
        handleProgressView(true)
        
        let myGroup = DispatchGroup()

        myGroup.enter() //for `checkSpeed`
        myGroup.enter() //for `doAnotherAsync`
        
        self.getTwilioAccessToken
        { (success) in
            if success
            {
                myGroup.leave()
            }
        }
        
        self.getAuthToken
        { (success) in
            if success
            {
                myGroup.leave()
            }
        }
        
        myGroup.notify(queue: DispatchQueue.global(qos: .background))
        {
            DispatchQueue.main.async
            {
                self.handleProgressView(false)
            }

            handler()
        }
    }
    
    /// Fetches the new twilio access token from server
    /// - Parameters:
    ///     - completion: the completion block.
    
    func getTwilioAccessToken(completion: @escaping ((Bool)->Void))
    {
        let providerCode = self.stateManager.loginViewModel.userProfile?.providerCode ?? ""

        self.stateManager.loginViewModel.getTwilioAccessToken(providerCode)
        { (respose, error) in
    
            if let validAccessToken = respose?.token, let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken)
            {
                print("Valid Refresh Token: \(validAccessToken)")
                
                TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData)
                { (error) in
                    
                    StateManager.shared.accessToken =  validAccessToken
                                                
                    if let error = error
                    {
                        NSLog("LOGIN: An error occurred while registering: \(error.localizedDescription)")
                    }
                    else
                    {
                        NSLog("LOGIN: Successfully registered for VoIP push notifications.")
                        self.expiryDate = Date().addingTimeInterval(60*60*24)
                        StateManager.shared.loginViewModel.userProfile?.twillioToken = validAccessToken
                    }
                }
            }
            if error != nil
            {
                completion(false)
            }
            else
            {
                completion(true)
            }
        }
    }
    
    /// Fetches the new auth token from server
    /// - Parameters:
    ///     - completion: the completion block.
    
    func getAuthToken(completion: @escaping ((Bool)->Void))
    {
        self.stateManager.loginViewModel.getAuthToken(with: self.stateManager.userName, password: self.stateManager.password)
        { (response, error) in
            
            DispatchQueue.main.async
            {
                if let validResponse = response, let validToken = validResponse.accessToken, let dataObject = try? JSONEncoder().encode(validResponse)
                {
                    UserDefaults.standard.setValue(dataObject, forKey: AppConstants.USER_ACCESS_TOKEN)
                    UserDefaults.standard.synchronize()
                }
                else
                {
                    // error
                    NotificationBanner(title: nil, subtitle: "Login Failed: \(response?.error ?? "Something went wrong")", style: .danger).show()
                }
            }
            
            if error != nil
            {
                completion(false)
            }
            else
            {
                completion(true)
            }
        }
    }
    
    /// Refreshes the twilio access token upon receiving a silent push
    
    func refreshTwilioAccessTokenOnSilentPush()
    {
        DispatchQueue.main.async
        {
            self.handleProgressView(true)
        }
        
        TwilioVoice.unregister(accessToken: StateManager.shared.accessToken, deviceToken: UserDefaults.standard.data(forKey: kCachedDeviceToken)!)
        { (error) in
            
            let providerCode = self.stateManager.loginViewModel.userProfile?.providerCode ?? ""
            self.stateManager.loginViewModel.getTwilioAccessToken(providerCode)
            { (respose, error) in
                
                if let validAccessToken = respose?.token, let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken)
                {
                    print("Valid Refresh Token: \(validAccessToken)")
                    
                    TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData)
                    { (error) in
                        
                        // End the task assertion.
                        
                        StateManager.shared.accessToken =  validAccessToken
                        
                        DispatchQueue.main.async
                        {
                            self.handleProgressView(false)
                        }
                        if let error = error
                        {
                            NSLog("LOGIN: An error occurred while registering: \(error.localizedDescription)")
                        }
                        else
                        {
                            NSLog("LOGIN: Successfully registered for VoIP push notifications.")
                            self.expiryDate = Date().addingTimeInterval(60*60*24)
                            StateManager.shared.loginViewModel.userProfile?.twillioToken = validAccessToken
                        }
                        
                        UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }
                }
            }
        }
    }
    
    // MARK:- UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration
    {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
    {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK:- RemoteNotification Registration
    
    func registerForPUSHNotifications()
    {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
        { (_, error) in
            
            guard error == nil else
            {
                print(error!.localizedDescription)
                return
            }
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler:
                                                                    {didAllow, error in
                                                                        
                                                                    })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
        updatedPushToken = nil
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("deviceToken: \(tokenString)")
        
        Messaging.messaging().apnsToken = deviceToken
        
        MessagingManager.sharedManager().registerChatClientWith(deviceToken: deviceToken)
        { (success, errorMessage) in

            if success
            {
            }
            else
            {
                self.updatedPushToken = deviceToken
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?)
    {
        print("Firebase registration token: \(fcmToken ?? "NO_TOKEN")")
        
        self.deviceIDFCM = fcmToken ?? ""
        let dataDict:[String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        
        Messaging.messaging().subscribe(toTopic: "all")
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
    // MARK:- RemoteNotification Receiving
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        let userInfo = notification.request.content.userInfo

        print(userInfo)
        
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        let messageType = userInfo["twi_message_type"] as? String ?? ""
        if messageType == "twilio.channel.new_message"
        {
            receivedNotification = userInfo
        }
        if var topController = keyWindow?.rootViewController
        {
            while let presentedViewController = topController.presentedViewController
            {
                topController = presentedViewController
            }
            if topController is ChatViewController  && messageType == "twilio.channel.new_message"
            {
                completionHandler([])
            }
            else
            {
                if topController is UINavigationController
                {
                    if let nav = topController as? UINavigationController
                    {
                        if nav.viewControllers[nav.viewControllers.count - 1] is ChatViewController && messageType == "twilio.channel.new_message"
                        {
                            completionHandler([])
                        }
                    }
                }
            }
            
        }
        
        // Change this to your preferred presentation option
        completionHandler([[.alert, .sound]])
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if let messageID = userInfo[gcmMessageIDKey]
        {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        let messageTitle:String = (((userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary)?["title"] as? String) ?? ""
        let messageBody:String = (((userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary)?["body"] as? String) ?? ""
        let tonumber:String = userInfo["tonumber"] as? String ?? ""
        let fromnumber:String = userInfo["fromnumber"] as? String ?? ""
        let module:String = userInfo["module"] as? String ?? "ch"
        let messageType:String = userInfo["twi_message_type"] as? String ?? ""

        if messageType == "twilio.channel.new_message"
        {
            let channelSID =  userInfo["channel_sid"] as? String ?? ""
            if channelSID.count > 0
            {
                let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

                if var topController = keyWindow?.rootViewController
                {
                    while let presentedViewController = topController.presentedViewController
                    {
                        topController = presentedViewController
                    }
                    if topController is ChatViewController
                    {
                        return
                    }
                    else
                    {
                        if topController is UINavigationController
                        {
                            if let nav = topController as? UINavigationController
                            {
                                if nav.viewControllers[nav.viewControllers.count - 1] is ChatViewController
                                {
                                    return
                                }
                            }
                        }
                    }
                }
                
                let leftView = UIImageView(image: #imageLiteral(resourceName: "mainlogo"))
                let banner = FloatingNotificationBanner(title: ((userInfo["aps"] as? [String:Any] ?? [String:Any]())["alert"] as? [String:Any] ?? [String:Any]())["title"] as? String ?? "", subtitle: ((userInfo["aps"] as? [String:Any] ?? [String:Any]())["alert"] as? [String:Any] ?? [String:Any]())["body"] as? String ?? "", leftView: leftView, style: .info, colors: CustomBannerColors())
                banner.show(cornerRadius: 7)
                banner.onTap =
                {
                    self.openChatViewWith(channelSID: channelSID, author: userInfo["author"] as? String ?? "")
                }
            }
            return
        }
        
        if module == "su"
        {
            // Status Update with Silent PUSH
            
            self.syncUserStatusWithWebLoggedInUser(staus: userInfo["status"] as? String ?? "")
        }
        
        if module == "TU" || module == "tu"
        {
            // Token Update with Silent PUSH
            
            DispatchQueue.global().async
            {
                // Request the task assertion and save the ID.
                
                self.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks")
                {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                    self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
                // TODO: Remove API Call, instead use the token from payload. 
                self.refreshTwilioAccessTokenOnSilentPush()
            }
        }
        
        if module == "cusu" || module == "cusu".capitalized
        {
            // Chat User Status Update with Silent PUSH
            
            var contactList = [ChatUserModel]()
            let defaults = UserDefaults(suiteName: "group.com.drcurves.toktiv")

            if let contactListData = defaults?.data(forKey: AppConstants.CONTACT_LIST)
            {
                if let list = try? JSONDecoder().decode([ChatUserModel].self, from: contactListData)
                {
                    contactList = list
                    let providerCode = userInfo["ProviderCode"] as? String ?? ""
                    for (index,contact) in contactList.enumerated()
                    {
                        var tempContact = contact
                        if providerCode.trimmingCharacters(in: .whitespaces) == contact.providerCode
                        {
                            tempContact.userOnline = userInfo["BrowserStatus"] as? Bool ?? false
                            tempContact.TwilioStatus = userInfo["TwilioStatus"] as? String ?? ""
                            
                            contactList[index] = tempContact
                            
                            if let contactsListData = try? JSONEncoder().encode(contactList)
                            {
                                defaults?.set(contactsListData, forKey: AppConstants.CONTACT_LIST)
                                defaults?.synchronize()
                            }
                        }
                    }
                }
            }
        }
        
        guard module == "c" else
        {
            // Conversations
            
            return
        }
        
        let state = UIApplication.shared.applicationState
        if state == .active  || state == .background
        {
            showAlertControllerWith(messageTitle: messageTitle, messageBody: messageBody)
            {
                self.openConversationView(fromnumber, toparam: tonumber)
            }
        }
        else if state == .inactive
        {
            print("state == .inactive || state == .background")
        }
        
        //        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    {
        // when Notification is tapped
        
        let userInfo = response.notification.request.content.userInfo
        
        if userInfo["twi_message_type"] as? String ?? "" == "twilio.channel.new_message"
        {
            receivedNotification = userInfo
        }
        
        let messageType:String = userInfo["twi_message_type"] as? String ?? ""

        if messageType == "twilio.channel.new_message"
        {
            let channelSID =  userInfo["channel_sid"] as? String ?? ""
            if channelSID.count > 0
            {
                let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

                if var topController = keyWindow?.rootViewController
                {
                    while let presentedViewController = topController.presentedViewController
                    {
                        topController = presentedViewController
                    }
                    if topController is ChatViewController
                    {
                        return
                    }
                    else
                    {
                        if topController is UINavigationController
                        {
                            if let nav = topController as? UINavigationController
                            {
                                if nav.viewControllers[nav.viewControllers.count - 1] is ChatViewController
                                {
                                    return
                                }
                            }
                        }
                    }
                }
                self.openChatViewWith(channelSID: channelSID, author: userInfo["author"] as? String ?? "")
            }
        }
        
        self.perform(#selector(self.showAlertOfNewMessage(_:)), with: userInfo, afterDelay: 1)
        completionHandler()
    }
    
    func handleSavedNotification()
    {
        if self.receivedNotification.count > 0
        {
            let userInfo = self.receivedNotification
            self.openChatViewWith(channelSID: userInfo["channel_sid"] as? String ?? "", author: userInfo["author"] as? String ?? "")
            self.receivedNotification = [AnyHashable : Any]()
        }
    }
    
    // MARK:- PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType)
    {
        NSLog("pushRegistry:didUpdatePushCredentials:forType:")
        UserDefaults.standard.set(credentials.token, forKey: kCachedDeviceToken)
        
        let tokenParts = credentials.token.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token(pushRegistry): \(token)")
        
        if let delegate = self.pushKitEventDelegate
        {
            delegate.credentialsUpdated(credentials: credentials)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType)
    {
        NSLog("pushRegistry:didInvalidatePushTokenForType:")
        
        if let delegate = self.pushKitEventDelegate
        {
            delegate.credentialsInvalidated()
        }
    }
    
    /**
     * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
     * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
     */
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType)
    {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        
        if let delegate = self.pushKitEventDelegate
        {
            delegate.incomingPushReceived(payload: payload)
        }
    }
    
    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void)
    {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion:")
        
        if let delegate = self.pushKitEventDelegate
        {
            delegate.incomingPushReceived(payload: payload, completion: completion)
        }
        
        if let version = Float(UIDevice.current.systemVersion), version >= 13.0
        {
            /**
             * The Voice SDK processes the call notification and returns the call invite synchronously. Report the incoming call to
             * CallKit and fulfill the completion before exiting this callback method.
             */
            completion()
        }
    }
    
}


// MARK:- Get Contact List API
extension AppDelegate
{
    
    func getContactList()
    {
        ChatViewModel.shared.getChatUserList( completion:
        { (response, error) in
            var contactsList = response ?? []
            contactsList = contactsList.filter{ $0.providerCode != StateManager.shared.loginViewModel.userProfile?.providerCode}
            if let contactsListData = try? JSONEncoder().encode(contactsList)
            {
                let defaults = UserDefaults(suiteName: "group.com.drcurves.toktiv")

                defaults?.set(contactsListData, forKey: AppConstants.CONTACT_LIST)
                defaults?.synchronize()
            }
        })
    }
    
    func findUserNameFor(providerCode:String) -> String
    {
        let defaults = UserDefaults(suiteName: "group.com.drcurves.toktiv")

        if let contactListData = defaults?.data(forKey: AppConstants.CONTACT_LIST)
        {
            if let list = try? JSONDecoder().decode([ChatUserModel].self, from: contactListData)
            {
                for contact in list
                {
                    if providerCode.trimmingCharacters(in: .whitespaces) == contact.providerCode
                    {
                        return contact.providerName ?? "No Name"
                    }
                }
            }
        }
        
        return providerCode
    }
}

extension UIApplication
{
    func topMostViewController() -> UIViewController?
    {
        return self.windows.filter {$0.isKeyWindow}.first?.rootViewController?.topMostViewController()
    }
}

extension UIViewController
{
    func topMostViewController() -> UIViewController
    {
        if self.presentedViewController == nil
        {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController
        {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController
        {
            if let selectedTab = tab.selectedViewController
            {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}
