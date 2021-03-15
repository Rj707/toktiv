//
//  LoginUserModel.swift
//  toktiv
//
//  Created by Developer on 13/11/2020.
//

import Foundation

struct LoginUserModel: Codable {
    let userId: Int?
    let userName: String?
    let email: String?
    let role: String?
    let type: String?
    let providerCode: String?
//    let password: String?
    let jobName: String?
//    let mb: String?
    let md: String?
    let employeeID: String?
//    let signature: String?
    let twilioNum: String?
    let fullName: String?
    let twillioToken:String?
    let workerSid:String?
    let twilioClientStatus:String?

    enum CodingKeys: String, CodingKey {
        case userId = "UserId"
        case userName = "UserName"
        case email = "Email"
        case role = "Role"
        case type = "Type"
        case providerCode = "ProviderCode"
//        case password = "Password"
        case jobName = "JobName"
//        case mb = "MB"
        case md = "MD"
        case employeeID = "EmployeeID"
//        case signature = "Signature"
        case twilioNum = "TwilioNum"
        case fullName = "FullName"
        case twillioToken = "TwillioToken"
        case workerSid = "WorkerSid"
        case twilioClientStatus = "TwilioClientStatus"
    }
}
