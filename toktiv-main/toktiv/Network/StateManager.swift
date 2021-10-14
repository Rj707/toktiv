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
            return UserDefaults.standard.value(forKey: "accessToken") as? String ?? ""
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
    
    var draftMessages:[DraftMessageModel] {
        set
        {
            let encoder = JSONEncoder()
            if let encoded = try? encoder.encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "draftMessages")
                UserDefaults.standard.synchronize()
            }
        }
        get
        {
            if let data = UserDefaults.standard.object(forKey: "draftMessages") as? Data {
                let decoder = JSONDecoder()
                if let draftMessages = try? decoder.decode([DraftMessageModel].self, from: data) {
                    return draftMessages
                }
            }
            return [DraftMessageModel]()
        }
    }
    
    func getDraftMessage(_ channelId:String)->String {
        for msg in draftMessages {
            if msg.channelId == channelId {
                return msg.message
            }
        }
        return ""
    }
    
    func saveDraftMessage(_ draftMessage: DraftMessageModel) {
        if !draftMessage.message.isEmpty {
            var isAlreadyExist = false
            var draftMessages = self.draftMessages
            for (index, value) in draftMessages.enumerated() {
                if value.channelId == draftMessage.channelId {
                    draftMessages[index].message = draftMessage.message
                    isAlreadyExist = true
                }
            }
            
            if !isAlreadyExist {
                draftMessages.append(draftMessage)
            }
            
            self.draftMessages = draftMessages
        }
        else {
            var draftMessages = self.draftMessages
            var selectedIndex = -1
            var isAlreadyExist = false
            for (index, value) in draftMessages.enumerated() {
                if value.channelId == draftMessage.channelId {
                    selectedIndex = index
                    isAlreadyExist = true
                }
            }
            if isAlreadyExist {
                draftMessages.remove(at: selectedIndex)
                self.draftMessages = draftMessages
            }
        }
    }
    
}
