//
//  StateManager.swift
//  toktiv
//
//  Created by Developer on 13/11/2020.
//

import Foundation

enum AvailableStatus: String {
    case online = "Idle"
    case offline = "Offline"
    case busy = "Busy"
}

class StateManager: NSObject {
    static let shared = StateManager()
    
    var currentStatus:AvailableStatus
    {
        get
        {
            return AvailableStatus(rawValue: UserDefaults.standard.value(forKey: "currentStatus") as? String ?? "") ?? .offline
        }
        set
        {
            UserDefaults.standard.set(newValue.rawValue , forKey: "currentStatus")
        }
    }
    var inCall:Bool = false
    
    var loginViewModel = LoginViewModel()
    var userHistoryViewModel = UserHistoryViewModel()
    var accessToken:String
    {
        set
        {
            UserDefaults.standard.set(newValue , forKey: "accessToken")
        }
        get
        {
            return UserDefaults.standard.value(forKey: "accessToken") as! String

        }
    }

    func setupWorkerStatus(_ status:String) {
        if status.lowercased().contains("idle") {
            self.currentStatus = .online
        }
        else if status.lowercased().contains("offline") {
            self.currentStatus = .offline
        }
        else if status.lowercased().contains("busy") {
            self.currentStatus = .busy
        }
    }
    
    var draftMessage:(String, String) {
        set
        {
            let draftMessage = ["channelId":newValue.0, "message":newValue.1]
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(draftMessage) {
                UserDefaults.standard.set(encoded, forKey: "draftMessage")
                UserDefaults.standard.synchronize()
            }
        }
        get
        {
            if let draftMessageData = UserDefaults.standard.object(forKey: "draftMessage") as? Data {
                let decoder = JSONDecoder()
                if let dict = try? decoder.decode([String:String].self, from: draftMessageData) {
                    return (dict["channelId"] as! String, dict["message"] as! String)
                }
            }
            return ("", "")
        }
    }
}
