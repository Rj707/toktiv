//
//  NetworkURLs.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//
//http://89.107.61.153/
import UIKit

class NetworkURLs: NSObject {
    static let GET_TOKEN_URL = "https://api.drcurves.com/AuthApi/token"
    static let GET_USER_PROFILE = "https://api.drcurves.com/AuthApi/api/MAccount/Login"
    static let GET_USER_CALL_HISTORY = "https://api.drcurves.com/AuthApi/api/UserCallHistory/GetProviderHistory"
    static let GET_USER_SMS_HISTORY = "https://api.drcurves.com/AuthApi/api/UserSMSHistory/GetProviderHistory"
    static let POST_NEW_MESSAGE = "https://api.drcurves.com/AuthApi/api/SmsSending/SendSms"
    static let TWILIO_ACCESS_TOKEN = "https://provider.drcurves.com/Token/GenerateIOSToken"
    static let GET_WORKER_STATUS = "https://api.drcurves.com/AuthApi/api/TaskrouterWorker/GetWorkerCurrentStatus"
    static let SET_WORKER_STATUS = "https://api.drcurves.com/AuthApi/api/WorkerStatus/UpdateWorkerStatus"
    static let GET_TASK_LIST = "https://api.drcurves.com/AuthApi/api/TaskQueues/GetAllTaskQueueDDL"
    static let ADD_MEMBER_TO_CALL =  "https://provider.drcurves.com/api/IOSCallConference/AddMemberToCall"
    //"https://c22e318f3b72.ngrok.io/api/IOSCallConference/AddMemberToCall"
        //"https://provider.drcurves.com/IOSCallConference/AddMemberToCall"
    //"https://e8f7668e899f.ngrok.io/IOSCallConference/AddMemberToCall"//
    static let GET_PATIENT_DETAILS = "https://api.drcurves.com/AuthApi/api/CallerDetails/getPatientDataByCellular"
    static let SEARCH_PATIENTS = "https://api.drcurves.com/AuthApi/api/PatientSearch/PatientSearchAuto"
    static let FROM_NUMBER = "https://api.drcurves.com/AuthApi/api/DialFromNumber/GetDialFromNumberDDL"
    static let COPY_CALLTASKS_TO_TASK = "https://api.drcurves.com/AuthApi/api/CallTasks/CopyTaskFromCallTasksToTasks"
    
    static let HOLD_IN_PROGRESS_CALL = "https://provider.drcurves.com/api/IOSHoldCall/HoldCall"
    static let RESUME_IN_PROGRESS_CALL = "https://provider.drcurves.com/api/IOSResumeCall/ResumeCall"
    
    static let GET_CHAT_USER_LIST = "https://provider.drcurves.com/api/ChatUserApi/GetProviderHistory"
    static let GET_CHAT_TOKEN = "https://provider.drcurves.com/chattoken/Generate"
    static let POST_CHAT_ATTACHMENT = "https://provider.drcurves.com/TwilioChat/UploadAttachment"

}

class AppConstants: NSObject {
    static let USER_ACCESS_TOKEN = "USER_ACCESS_TOKEN"
    static let USER_PROFILE_MODEL = "USER_PROFILE_MODEL"
    static let LAST_INBOUND_CALL_DATE = "LAST_INBOUND_CALL_DATE"
    static let WAIT_TIME_IN_SECONDS = "WAIT_TIME_IN_SECONDS"
    
//    static let ACCOUNT_SID = "AC0f1a4b6ec426b7c775e3663d6e8e947b"
//    static let API_KEY = "SKd5b70399a2d8d9fb7a746563edae75fb"
//    static let API_KEY_SECRET = "KUUAIXDhbafIRfHtpEMqhRuIBBh0VdgN"
//    static let APP_SID = "AP1cbae8323787c0498d93d704c0eea095"
}
//
