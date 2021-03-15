//
//  UserHistoryViewModel.swift
//  toktiv
//
//  Created by Developer on 14/11/2020.
//

import Foundation

typealias GetUserCallHistory = ([HistoryResponseElement]?, String?) -> Void
typealias PostNewMessage = (SendMessageResponse?, String?) -> Void

class UserHistoryViewModel: NSObject {
    static let shared = UserHistoryViewModel()
    
    var currentCalls:[HistoryResponseElement] = []
    var currenSMSs:[HistoryResponseElement] = []
    
    func getUserCallHistory(providerCode:String, accessToken:String, completion: @escaping GetUserCallHistory) {
        let queryParms = ["providerCode":providerCode]
        let requestHeaders = ["Authorization": "bearer \(accessToken)", "Content-Type":"application/json"]

        BaseService.getWithoutQueryParameters(NetworkURLs.GET_USER_CALL_HISTORY, query: queryParms, headers: requestHeaders, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode([HistoryResponseElement].self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func getUserSMSHistory(providerCode:String, from:String, to:String, type:String, completion: @escaping GetUserCallHistory) {
        let queryParms = ["providerCode":providerCode, "from":from, "type":type,"to":to]
        BaseService.getWithoutQueryParameters(NetworkURLs.GET_USER_SMS_HISTORY, query: queryParms, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode([HistoryResponseElement].self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func sendMessage(_ accessToken:String, message:String, from:String, to:String, completion: @escaping PostNewMessage) {
        let bodyParams = ["From":from, "To":to, "Message": message]
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)
        let requestHeaders = ["Authorization": "bearer \(accessToken)", "Content-Type":"application/json"]

        BaseService.post(NetworkURLs.POST_NEW_MESSAGE, query: nil, headers: requestHeaders, body: bodyData) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(SendMessageResponse.self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
}
