
import Foundation

public struct ChatUserModel : Codable {

	let channelSid : String?
	let chatUserSid : String?
	let dEA : String?
	let eMPJob : String?
	let empID : String?
	let providerCode : String?
	let providerName : String?
	let userOnline : Bool?


	enum CodingKeys: String, CodingKey {
        
		case channelSid = "ChannelSid"
		case chatUserSid = "ChatUserSid"
		case dEA = "DEA"
		case eMPJob = "EMPJob"
		case empID = "EmpID"
		case providerCode = "ProviderCode"
		case providerName = "ProviderName"
		case userOnline = "UserOnline"
	}
    
    public init(from decoder: Decoder) throws {
        
		let values = try decoder.container(keyedBy: CodingKeys.self)
		channelSid = try values.decodeIfPresent(String.self, forKey: .channelSid)
		chatUserSid = try values.decodeIfPresent(String.self, forKey: .chatUserSid)
		dEA = try values.decodeIfPresent(String.self, forKey: .dEA)
		eMPJob = try values.decodeIfPresent(String.self, forKey: .eMPJob)
		empID = try values.decodeIfPresent(String.self, forKey: .empID)
		providerCode = try values.decodeIfPresent(String.self, forKey: .providerCode)
		providerName = try values.decodeIfPresent(String.self, forKey: .providerName)
		userOnline = try values.decodeIfPresent(Bool.self, forKey: .userOnline)
	}


}

public struct ChatTokenModel : Codable {
    
    let identity : String?
    let token : String?
    
    enum CodingKeys: String, CodingKey {
        
        case identity = "identity"
        case token = "token"
    }
    
    public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        identity = try values.decodeIfPresent(String.self, forKey: .identity)
        token = try values.decodeIfPresent(String.self, forKey: .token)
    }
    
}
