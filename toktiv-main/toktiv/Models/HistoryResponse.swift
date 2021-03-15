//
//  UserCallHistoryResponse.swift
//  toktiv
//
//  Created by Developer on 13/11/2020.
//

import Foundation

// MARK: - CallHistoryResponseElement

struct HistoryResponseElement: Codable {
//    let recordingname: JSONNull?
    let starttime: String?
    let duration: String?
    let type: String?
    let to: String?
    let from: String?
    let toName: String?
    let fromName: String?
    let result: String?
    let direction: String?
    let subject: String?
    let content: String?
    let date: String?
    let time: String?
    let taskID: String?
    let isRecorded: String?

    enum CodingKeys: String, CodingKey {
//        case recordingname = "recordingname"
        case starttime = "starttime"
        case duration = "duration"
        case type = "type"
        case to = "To"
        case from = "From"
        case toName = "toName"
        case fromName = "FromName"
        case result = "result"
        case direction = "Direction"
        case subject = "Subject"
        case content = "Content"
        case date = "Date"
        case time = "Time"
        case taskID = "TaskID"
        case isRecorded = "IsRecorded"
    }
    
    init(with to:String, from:String, direction:String) {
        starttime = ""
        duration = ""
        type = ""
        toName = ""
        fromName = ""
        result = ""
        subject = ""
        content = ""
        date = ""
        time = ""
        taskID = ""
        isRecorded = ""
        self.to = to
        self.from = from
        self.direction = direction
        
    }
}
