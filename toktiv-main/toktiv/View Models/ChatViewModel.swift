//
//  ChatViewModel.swift
//  toktiv
//
//  Created by Hafiz Saad on 08/07/2021.
//

import UIKit
import MBProgressHUD

typealias GetChatUserList = ([ChatUserModel]?, String?) -> Void
typealias GetChatToken = (ChatTokenModel?, String?) -> Void
typealias DownloadChatAttachment = (UIImage?, String?) -> Void
typealias UploadChatAttachment = (String?) -> Void
class ChatViewModel: NSObject {
    
    static let shared = ChatViewModel()
    
    func getChatUserList(completion: @escaping GetChatUserList) {

        BaseService.getWithoutQueryParameters(NetworkURLs.GET_CHAT_USER_LIST, query: nil, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode([ChatUserModel].self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func generateTwilioChatToken(completion: @escaping GetChatToken) {
        
        let bodyParams = ["identity":StateManager.shared.loginViewModel.userProfile?.providerCode ?? ""]
//        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)
        
        BaseService.post(NetworkURLs.GET_CHAT_TOKEN, query: bodyParams, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ChatTokenModel.self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func downloadImageWithURL(url:String, completion: @escaping DownloadChatAttachment)
    {
        
        BaseService.getWithoutQueryParameters(url, query: nil, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                return
            }
            
            if let image = UIImage(data: responseData, scale:1)
            {
                completion(image,nil)
            }
            else
            {
                completion(nil,"")
            }
        }
    }
    
    func uploadChatAttachment(attachment:Data, contentType: String, filename: String, progressHud: MBProgressHUD, completion: @escaping UploadChatAttachment)
    {
        BaseService.upload(imgData: attachment, with: NetworkURLs.POST_CHAT_ATTACHMENT, contentType: contentType, filename: filename, progressHud: progressHud, completionHandler: { (dictionary, error, data) in
            guard data != nil else {
                return
            }
            
            if dictionary?.value(forKey: "res") as! Int == 1
            {
                completion(dictionary?.value(forKey: "data") as? String)
            }
            else
            {
                completion("")
            }
        })
    }
    
    

}
