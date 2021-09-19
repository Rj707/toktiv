import UIKit
import TwilioChatClient

enum CustomError: Error {
    // Throw when an invalid password is entered
    case invalidPassword

    // Throw when an expected resource is not found
    case notFound

    // Throw in all other cases
    case unexpected(code: Int)
}

protocol ChannelManagerDelegate
{
    
    func reloadChannelDescriptorList()
}

class ChannelManager: NSObject
{
    
    static let sharedManager = ChannelManager()
    
//    static let defaultChannelUniqueName = "general"
//    static let defaultChannelName = "General Channel"
    
    var delegate:ChannelManagerDelegate?
    
    var channelsList:TCHChannels?
    var channelDescriptors:NSOrderedSet?
    var currentChannel:TCHChannel!
    
    override init()
    {
        super.init()
        channelDescriptors = NSMutableOrderedSet()
    }
    
    // MARK: - General channel
    
    func joinChatRoomWith(name: String, completion: @escaping (Bool, Error?) -> Void)
    {
        
        let uniqueName = name
        if let channelsList = self.channelsList
        {
            channelsList.channel(withSidOrUniqueName: uniqueName)
            { result, channel in
                
                self.currentChannel = channel
                
                if self.currentChannel != nil
                {
                    if self.currentChannel.status == .joined
                    {
                        completion(true, nil)
                        return
                    }
                    
                    self.joinChatRoomWithUniqueName(name: nil, completion: completion)
                }
                else
                {
                    self.createChatRoomWithUniqueName(name: uniqueName)
                    { succeeded,error  in
                        if (succeeded)
                        {
                            self.joinChatRoomWithUniqueName(name: uniqueName, completion: completion)
                            return
                        }
                        completion(false,error)
                    }
                }
            }
        }
        else
        {
            completion(false,CustomError.unexpected(code: 111))
        }
    }
    
    func joinChatRoomWithUniqueName(name: String?, completion: @escaping (Bool, Error?) -> Void)
    {
        currentChannel.join
        { result in
            
            if ((result.isSuccessful()) && name != nil)
            {
                self.setChatRoomUniqueNameWithCompletion(name: name!, completion: completion)
                return
            }
            completion((result.isSuccessful()), result.error)
        }
    }
    
    func createChatRoomWithUniqueName(name: String, completion: @escaping (Bool, Error?) -> Void)
    {
        let channelName = name
        
        let options =
            [
                TCHChannelOptionFriendlyName: channelName,
                TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        
        channelsList!.createChannel(options: options)
        { result, channel in
            
            if (result.isSuccessful())
            {
                self.currentChannel = channel
            }
            completion((result.isSuccessful()), result.error)
        }
    }
    
    func setChatRoomUniqueNameWithCompletion(name: String, completion:@escaping (Bool, Error?) -> Void)
    {
        currentChannel.setUniqueName(name)
        { result in
            completion((result.isSuccessful()), result.error)
        }
    }
    
    // MARK: - Populate channel Descriptors
    
    func populateChannelDescriptors() {
        
        channelsList?.userChannelDescriptors { result, paginator in
            guard let paginator = paginator else {
                return
            }

            let newChannelDescriptors = NSMutableOrderedSet()
            newChannelDescriptors.addObjects(from: paginator.items())
            self.channelsList?.publicChannelDescriptors { result, paginator in
                guard let paginator = paginator else {
                    return
                }

                // de-dupe channel list
                let channelIds = NSMutableSet()
                for descriptor in newChannelDescriptors {
                    if let descriptor = descriptor as? TCHChannelDescriptor {
                        if let sid = descriptor.sid {
                            channelIds.add(sid)
                        }
                    }
                }
                for descriptor in paginator.items() {
                    if let sid = descriptor.sid {
                        if !channelIds.contains(sid) {
                            channelIds.add(sid)
                            newChannelDescriptors.add(descriptor)
                        }
                    }
                }
                
                
                // sort the descriptors
                let sortSelector = #selector(NSString.localizedCaseInsensitiveCompare(_:))
                let descriptor = NSSortDescriptor(key: "friendlyName", ascending: true, selector: sortSelector)
                newChannelDescriptors.sort(using: [descriptor])
                
                self.channelDescriptors = newChannelDescriptors
                
                if let delegate = self.delegate {
                    delegate.reloadChannelDescriptorList()
                }
            }
        }
    }
    
    
    // MARK: - Create channel
    
    func createChannelWithName(name: String, completion: @escaping (Bool, TCHChannel?) -> Void)
    {
        let channelOptions =
        [
            TCHChannelOptionFriendlyName: name,
            TCHChannelOptionType: TCHChannelType.public.rawValue
        ] as [String : Any]
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        
        self.channelsList?.createChannel(options: channelOptions)
        { result, channel in
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            completion((result.isSuccessful()), channel)
        }
    }
}

// MARK: - TwilioChatClientDelegate
extension ChannelManager : TwilioChatClientDelegate
{
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel)
    {
        DispatchQueue.main.async
        {
            self.populateChannelDescriptors()
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate)
    {
        DispatchQueue.main.async
        {
            self.delegate?.reloadChannelDescriptorList()
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel)
    {
        DispatchQueue.main.async
        {
            self.populateChannelDescriptors()
        }
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus)
    {
        
    }
}

// For each error type return the appropriate localized description
extension CustomError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return NSLocalizedString(
                "The provided password is not valid.",
                comment: "Invalid Password"
            )
        case .notFound:
            return NSLocalizedString(
                "The specified item could not be found.",
                comment: "Resource Not Found"
            )
        case .unexpected(_):
            return NSLocalizedString(
                "An unexpected error occurred.",
                comment: "Unexpected Error"
            )
        }
    }
}
