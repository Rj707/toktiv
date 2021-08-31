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
            if let endDate = self.expiryDate
            {
                let differenceInSeconds = Int(endDate.timeIntervalSince(Date()))
                print("Setting Timmer for :\(differenceInSeconds)")
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(differenceInSeconds), target: self, selector: #selector(getAcesstokenRefreshed), userInfo: nil, repeats: false)
            }
        }
    }
    
    // MARK:- Implementation
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        
        NSLog("Twilio Voice Version: %@", TwilioVoice.sdkVersion())
        
        initializePushKit()
        
        registerForPUSHNotifications()
        
        Messaging.messaging().delegate = self
        
        //get application instance ID
        InstanceID.instanceID().instanceID
        { (result, error) in
            
            if let error = error
            {
                print("Error fetching remote instance ID: \(error)")
            }
            else if let result = result
            {
                print("Remote instance ID token: \(result.token)")
            }
        }
        
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
                MBProgressHUD.showAdded(to: topController.view, animated: true)
            }
            else
            {
                MBProgressHUD.hide(for: topController.view, animated: true)
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
            
            controller.toName = author
            
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
            
            if var topController = keyWindow?.rootViewController
            {
                while let presentedViewController = topController.presentedViewController
                {
                    topController = presentedViewController
                }
                
                // topController should now be your topmost view controller
                if topController is UINavigationController {
                    (topController as? UINavigationController)?.pushViewController(controller, animated: true)
                }
                else
                {
                    let nav = UINavigationController.init()
                    nav.pushViewController(controller, animated: true)
                }
//                topController.present(controller, animated: true, completion: nil)
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
        //        let messageTitle:String = (((userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary)?["title"] as? String) ?? ""
        //        let messageBody:String = (((userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary)?["body"] as? String) ?? ""
        
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
    
    // MARK:- Access Token
    
    func handleAccessTokenExpiry(_ accessToken:String)
    {
        let jwtDictionary = JWTDecoder.decode(jwtToken: accessToken)
        if let exp = jwtDictionary["exp"] as? Double
        {
            if let delegate = UIApplication.shared.delegate as? AppDelegate
            {
                delegate.expiryDate = Date(timeIntervalSince1970: exp)
                //                 delegate.expiryDate =  Date().addingTimeInterval(60*5)
            }
        }
    }
    
    @objc func getAcesstokenRefreshed()
    {
        if let validExpDate = self.expiryDate
        {
            let expDate = validExpDate.toLocalTime()
            let currentDate = Date().toLocalTime()
            
            if expDate <= currentDate
            {
                handleProgressView(true)
                
                let providerCode = self.stateManager.loginViewModel.userProfile?.providerCode ?? ""
                self.stateManager.loginViewModel.getTwilioAccessToken(providerCode) { (respose, error) in
                    if let validAccessToken = respose?.token, let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken)
                    {
                        print("Valid Refresh Token: \(validAccessToken)")
                        
                        TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData)
                        { (error) in
                            
                            StateManager.shared.accessToken =  validAccessToken
                            
                            self.handleProgressView(false)
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
                    
                }
            }
        }
    }
    
    func refreshAccessTokenOnSilentPush()
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
        { (success) in
            
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
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
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
            //            if status in payload is 'Available' or 'Idle' then status will be Online or whatever word you are using for Online
            //            if status in payload is 'Offline' or 'Unavailable' then status will be Online or whatever word you are using for Offline
            //            if status in payload is 'Busy' or 'WrapUp' then status will be Online or whatever word you are using for Busy
            
            self.syncUserStatusWithWebLoggedInUser(staus: userInfo["status"] as? String ?? "")
        }
        
        if module == "TU" || module == "tu"
        {
            DispatchQueue.global().async
            {
                // Request the task assertion and save the ID.
                
                self.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: "Finish Network Tasks")
                {
                    // End the task if time expires.
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                    self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
                
                self.refreshAccessTokenOnSilentPush()
            }
        }
        
        guard module == "c" else
        {
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        // Background Notification
        
        let userInfo = response.notification.request.content.userInfo
        
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
                }
                self.openChatViewWith(channelSID: channelSID, author: userInfo["author"] as? String ?? "")
            }
        }
        
        self.perform(#selector(self.showAlertOfNewMessage(_:)), with: userInfo, afterDelay: 1)
        completionHandler()
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
    
    //    // For iOS 10 and later; do not forget to set up a delegate for UNUserNotificationCenter
    //    func userNotificationCenter(_ center: UNUserNotificationCenter,
    //                                didReceive response: UNNotificationResponse,
    //                                withCompletionHandler completionHandler:
    //                                    @escaping () -> Void)
    //    {
    //        let userInfo = response.notification.request.content.userInfo
    //
    //        if let chatClient = MessagingManager.sharedManager().client, chatClient.user != nil
    //        {
    //            // If your reference to the Chat client exists and is initialized, send the notification to it
    //            chatClient.handleNotification(userInfo)
    //            { (result) in
    //
    //                if (!result.isSuccessful())
    //                {
    //                    // Handling of notification was not successful, retry?
    //                }
    //            }
    //        }
    //        else
    //        {
    //            // Store the notification for later handling
    //            receivedNotification = userInfo
    //        }
    //    }
    //
    //    // For iOS versions before 10
    //    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    //    {
    //        // If your application supports multiple types of push notifications, you may wish to limit which ones you send to the TwilioChatClient here
    //
    //        if let chatClient = MessagingManager.sharedManager().client, chatClient.user != nil
    //        {
    //            // If your reference to the Chat client exists and is initialized, send the notification to it
    //            chatClient.handleNotification(userInfo)
    //            { (result) in
    //                if (!result.isSuccessful())
    //                {
    //                    // Handling of notification was not successful, retry?
    //                }
    //            }
    //        }
    //        else
    //        {
    //            // Store the notification for later handling
    //            receivedNotification = userInfo
    //        }
    //    }
    
}
