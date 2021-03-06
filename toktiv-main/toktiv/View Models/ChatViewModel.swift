//
//  ChatViewModel.swift
//  toktiv
//
//  Created by Hafiz Saad on 08/07/2021.
//

import UIKit

typealias GetChatUserList = ([ChatUserModel]?, String?) -> Void

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


}
