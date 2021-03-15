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
    
    var currentStatus:AvailableStatus = .online
    var inCall:Bool = false
    
    var loginViewModel = LoginViewModel()
    var userHistoryViewModel = UserHistoryViewModel()
    
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
