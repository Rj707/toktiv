import UIKit
import TwilioChatClient

class MessagingManager: NSObject {
    
    static let _sharedManager = MessagingManager()
    
    var client:TwilioChatClient?
    var delegate:ChannelManager?
    var connected = false
    
    var userIdentity:String {
        return SessionManager.getUsername()
    }
    
    var hasIdentity: Bool {
        return SessionManager.isLoggedIn()
    }
    
    override init() {
        super.init()
        delegate = ChannelManager.sharedManager
    }
    
    class func sharedManager() -> MessagingManager {
        return _sharedManager
    }
    
    // MARK: User and session management
    
    func logout() {
        SessionManager.logout()
        DispatchQueue.global(qos: .userInitiated).async {
            self.client?.shutdown()
            self.client = nil
        }
        self.connected = false
    }
    
    // MARK: Twilio Client
    
    func connectClientWithCompletion(completion: @escaping (Bool, NSError?) -> Void) {
        if (client != nil) {
            logout()
        }
        
        requestTokenWithCompletion { succeeded, token in
            if let token = token, succeeded {
                self.initializeClientWithToken(token: token)
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not get access token", code:301)
                completion(succeeded, error)
            }
        }
    }
    
    func initializeClientWithToken(token: String) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) { [weak self] result, chatClient in
            guard (result.isSuccessful()) else { return }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self?.connected = true
            self?.client = chatClient
            
            self?.registerChatClientWith(deviceToken: (UIApplication.shared.delegate as! AppDelegate).updatedPushToken ?? Data.init())
            { (success) in
                
                if success
                {
                }
                else
                {
                }
            }
        }
    }
    
    func requestTokenWithCompletion(completion:@escaping (Bool, String?) -> Void) {
        
        ChatViewModel.shared.generateTwilioChatToken { (chatTokenModle, errorMessage) in
            
            var token: String?
            token = chatTokenModle?.token
            completion(token != nil, token)
            
        }
        
    }
    
    func errorWithDescription(description: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: "app", code: code, userInfo: userInfo)
    }
    
    func registerChatClientWith(deviceToken: Data, completion : @escaping (Bool) -> ())
    {
        if let chatClient = self.client, chatClient.user != nil
        {
            chatClient.register(withNotificationToken: deviceToken)
            { (result) in
                
                completion(true)

                if (!result.isSuccessful())
                {
                    // try registration again or verify token
                }
            }
        }
        else
        {
            completion(false)
        }
    }
}

// MARK: - TwilioChatClientDelegate
extension MessagingManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        self.delegate?.chatClient(client, channelAdded: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        self.delegate?.chatClient(client, channelDeleted: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        if status == TCHClientSynchronizationStatus.completed {
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            ChannelManager.sharedManager.channelsList = client.channelsList()
            ChannelManager.sharedManager.populateChannelDescriptors()
            
        }
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
    
    func chatClientTokenWillExpire(_ client: TwilioChatClient) {
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
                client.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
    
    func chatClientTokenExpired(_ client: TwilioChatClient) {
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
                client.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
}
