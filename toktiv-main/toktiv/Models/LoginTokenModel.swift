//
//  LoginToken.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import Foundation

struct LoginTokenModel: Codable {
    let accessToken: String?
    let tokenType: String?
    let expiresIn: Int?
    let issued: String?
    let expires: String?
    let error:String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case issued = ".issued"
        case expires = ".expires"
        case error = "error"
    }
}


// MARK: - TwilioAccessResponse
struct TwilioAccessResponse: Codable {
    let token: String?
    let agentId: String?

    enum CodingKeys: String, CodingKey {
        case token
        case agentId
    }
}


// MARK: - Send Message Response
struct SendMessageResponse: Codable {
    let res: Int?
    let data: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case res
        case data
        case message = "Message"
    }
}

// MARK: - ActiveTasksResponseElement
struct ActiveTask: Codable {
    let cellNumber: String?
    let taskGroupID: Int?
    let taskGroupName: String?
    let taskQueue: String?

    enum CodingKeys: String, CodingKey {
        case cellNumber = "CellNumber"
        case taskGroupID = "TaskGroupID"
        case taskGroupName = "TaskGroupName"
        case taskQueue = "TaskQueue"
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cellNumber = try? container.decode(String.self, forKey: .cellNumber)
        taskGroupName = try? container.decode(String.self, forKey: .taskGroupName)
        taskQueue = try? container.decode(String.self, forKey: .taskQueue)
        
        do {
            taskGroupID = try container.decode(Int.self, forKey: .taskGroupID)
        } catch {
            let stringValue = try? container.decode(String.self, forKey: .taskGroupID)
            taskGroupID = Int(stringValue ?? "0") ?? 0
        }
    }
}


struct PatientDetails: Codable {
    let status: String?
    let data: [PatientDatum]?
    var direction:String?

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case data = "data"
        case direction = "direction"
    }
}

// MARK: - Datum
struct PatientDatum: Codable {
    let patientID: String?
    let firstName: String?
    let lastName: String?
    let dateOfBirth: String?
    let groupName: String?
    let title: String?
    let gender: String?
    let taskID: String?

    enum CodingKeys: String, CodingKey {
        case patientID = "PatientID"
        case firstName = "FirstName"
        case lastName = "LastName"
        case dateOfBirth = "DateOfBirth"
        case groupName = "GroupName"
        case title = "Title"
        case gender = "Gender"
        case taskID = "TaskID"
    }
}


// MARK: - SearchedPatient
struct SearchedPatient: Codable {
    let status: String?
    let data: [Patient]?

    enum CodingKeys: String, CodingKey {
        case status = "status"
        case data = "data"
    }
}

// MARK: - Datum
struct Patient: Codable {
    let patientID: String?
    let name: String?
    let chartNumber: String?
    let gender: String?
    let email: String?
    let primaryDr: String?
    let dateOfBirth: String?
    let cellNumber: String?
    let country: String?
    let phone: String?
    let fbName: String?
    let igName: String?
    let twtName: String?
    let office: String?
    let cd: String?
    let md: String?
    let info: String?

    enum CodingKeys: String, CodingKey {
        case patientID = "PatientID"
        case name = "Name"
        case chartNumber = "ChartNumber"
        case gender = "Gender"
        case email = "Email"
        case primaryDr = "PrimaryDr"
        case dateOfBirth = "DateOfBirth"
        case cellNumber = "CellNumber"
        case country = "Country"
        case phone = "Phone"
        case fbName = "fbName"
        case igName = "igName"
        case twtName = "twtName"
        case office = "Office"
        case cd = "CD"
        case md = "MD"
        case info = "INFO"
    }
}
