import UIKit
import TwilioChatClient
import MBProgressHUD

class MessagingManager: NSObject
{
    static let _sharedManager = MessagingManager()
    
    var chatClient:TwilioChatClient?
    var delegate:ChannelManager?
    var connected = false
    
    override init()
    {
        super.init()
        delegate = ChannelManager.sharedManager
    }
    
    class func sharedManager() -> MessagingManager
    {
        return _sharedManager
    }
    
    // MARK: User and session management
    
    func logout(completion : @escaping (Bool, String?) -> ())
    {
        SessionManager.logout()
        
        DispatchQueue.main.async
        {
            if let chatClient = self.chatClient, chatClient.user != nil
            {
                self.deregisterChatClientWith(deviceToken: (UIApplication.shared.delegate as! AppDelegate).updatedPushToken ?? Data.init())
                { (success, errorMessage) in
                    if success
                    {
                        self.chatClient?.shutdown()
                        self.chatClient = nil
                        self.delegate = nil
                        self.connected = false
                        completion(success, nil)
                    }
                    else
                    {
                        completion(false, errorMessage)
                    }
                }
            }
            
        }
    }
    
    // MARK: Twilio Client
    
    func connectClientWithCompletion(completion: @escaping (Bool, NSError?) -> Void)
    {
        if (chatClient != nil)
        {
            logout
            { (success, errorMessage) in
                
            }
        }
        
        self.requestTokenWithCompletion
        { succeeded, token in
            
            if let token = token, succeeded
            {
                self.initializeClientWithToken(token: token)
                { (succcess, error) in
                
                    completion(succcess, error)
                }
            }
            else
            {
                let error = self.errorWithDescription(description: "Error while trying to get chat access token from server", code:301)
                completion(succeeded, error)
            }
        }
    }
    
    func requestTokenWithCompletion(completion:@escaping (Bool, String?) -> Void)
    {
        /* Get twilio chat token from server */

        ChatViewModel.shared.generateTwilioChatToken
        { (chatTokenModle, errorMessage) in
            
            var token: String?
            token = chatTokenModle?.token
            completion(token != nil, token)
        }
    }
    
    func initializeClientWithToken(token: String, completion:@escaping (Bool, NSError?) -> Void)
    {
        DispatchQueue.main.async
        {
//            MBProgressHUD.showAdded(to: UIApplication.shared.topMostViewController()?.view ?? UIView.init(), animated: true).label.text = "Syncing Channels"
        }
        
        TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self)
        { [weak self] result, chatClient in
            
            guard (result.isSuccessful()) else
            {
                completion(false, result.error)
                return
            }
            
//            MBProgressHUD.hide(for: UIApplication.shared.topMostViewController()?.view ?? UIView.init(), animated: true)

            self?.connected = true
            self?.chatClient = chatClient
            
            completion(true, nil)
            
            self?.registerChatClientWith(deviceToken: (UIApplication.shared.delegate as! AppDelegate).updatedPushToken ?? Data.init())
            { (success, errorMessage) in
                
            }
        }
    }
    
    func registerChatClientWith(deviceToken: Data, completion : @escaping (Bool, String?) -> ())
    {
        /* Register APNS token for push notification updates. */

        if let chatClient = self.chatClient, chatClient.user != nil
        {
            chatClient.register(withNotificationToken: deviceToken)
            { (result) in
                
                if (!result.isSuccessful())
                {
                    // try registration again or verify token
                    completion(false,result.error?.localizedDescription)
                }
                else
                {
                    completion(true,nil)
                }
            }
        }
        else
        {
            completion(false,"TwilioChatClient is nil")
        }
    }
    
    func deregisterChatClientWith(deviceToken: Data, completion : @escaping (Bool, String?) -> ())
    {
        if let chatClient = self.chatClient, chatClient.user != nil
        {
            chatClient.deregister(withNotificationToken: deviceToken)
            { (result) in
                
                if (!result.isSuccessful())
                {
                    // try registration again or verify token
                    completion(false,result.error?.localizedDescription)
                }
                else
                {
                    completion(true,nil)
                }
            }
        }
        else
        {
            completion(false,"TwilioChatClient is nil")
        }
    }
    
    //MARK: - Helper
    
    func errorWithDescription(description: String, code: Int) -> NSError
    {
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: "app", code: code, userInfo: userInfo)
    }
}

// MARK: - TwilioChatClientDelegate

extension MessagingManager : TwilioChatClientDelegate
{
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel)
    {
        self.delegate?.chatClient(client, channelAdded: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate)
    {
        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel)
    {
        self.delegate?.chatClient(client, channelDeleted: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus)
    {
        //* Called when the client synchronization state changes during startup.

        if status == .completed
        {
            ChannelManager.sharedManager.channelsList = client.channelsList()
            ChannelManager.sharedManager.populateChannelDescriptors()
        }
        if status == .channelsListCompleted
        {
            ChannelManager.sharedManager.channelsList = client.channelsList()
            ChannelManager.sharedManager.populateChannelDescriptors()
            
            NotificationCenter.default.post(name: NSNotification.Name.init("kChannelsListCompleted"), object: nil)
        }
        
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
    
    func chatClientTokenWillExpire(_ client: TwilioChatClient)
    {
        requestTokenWithCompletion
        { succeeded, token in
            
            if (succeeded)
            {
                client.updateToken(token!)
            }
            else
            {
                print("Error while trying to get new access token")
            }
        }
    }
    
    func chatClientTokenExpired(_ client: TwilioChatClient)
    {
        requestTokenWithCompletion
        { succeeded, token in
            
            if (succeeded)
            {
                client.updateToken(token!)
            }
            else
            {
                print("Error while trying to get new access token")
            }
        }
    }
}
