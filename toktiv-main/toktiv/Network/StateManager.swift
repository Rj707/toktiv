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
            return AvailableStatus(rawValue: UserDefaults.standard.value(forKey: "currentStatus") as! String)!
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
}
