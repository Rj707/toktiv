//
//  LoginViewModel.swift
//  toktiv
//
//  Created by Developer on 13/11/2020.
//

import UIKit
import MBProgressHUD

typealias GetUserAccessToken = (LoginTokenModel?, String?) -> Void
typealias GetUserProfile = (LoginUserModel?, String?) -> Void
typealias GetTwilioAccessToken = (TwilioAccessResponse?, String?) -> Void
typealias WorkerStatuesCompletion = (WorkerStatusModel?, String?) -> Void
typealias ActiveTaskCompletion = ([ActiveTask]?, String?) -> Void
typealias AddToCallResponse = (SendMessageResponse?, String?) -> Void
typealias PatientDetailResponse = (PatientDetails?, String?) -> Void
typealias PatientSearchResponse = (SearchedPatient?, String?) -> Void
typealias HoldResumeResponse = (SendMessageResponse?, String?) -> Void


class LoginViewModel: NSObject {
    
    static let shared = LoginViewModel()
    
    var userProfile: LoginUserModel?
    var defaultPhoneNumber:String = ""
    var userFromNumbers:[ActiveTask] = []
    
    var userAccessToken:String {
        
        if let data = UserDefaults.standard.data(forKey: AppConstants.USER_ACCESS_TOKEN), let response = try? JSONDecoder().decode(LoginTokenModel.self, from: data) {
            return response.accessToken ?? ""
        }
        
        return ""
    }
    
    
    func getAuthToken(with username:String, password:String, completion: @escaping GetUserAccessToken) {
        let bodyData = "username=\(username)&password=\(password)&grant_type=password".data(using: .utf8)
        BaseService.post(NetworkURLs.GET_TOKEN_URL, query: nil, headers: nil, body: bodyData) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let userToken = try decoder.decode(LoginTokenModel.self, from: responseData)
                completion(userToken, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func getUserProfile(with accessToken:String, username:String, password:String, completion: @escaping GetUserProfile) {
        var deviceToken:String = ""
        if let appdelegate = UIApplication.shared.delegate as? AppDelegate {
            deviceToken = appdelegate.deviceIDFCM
        }
        
        let bodyParams = ["UserName":username, "Password":password, "DeviceID":deviceToken]
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)
        let requestHeaders = ["Authorization": "bearer \(accessToken)", "Content-Type":"application/json"]

        BaseService.post(NetworkURLs.GET_USER_PROFILE, query: nil, headers: requestHeaders, body: bodyData) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(LoginUserModel.self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func getTwilioAccessToken(_ providerCode:String, completion: @escaping GetTwilioAccessToken) {
        BaseService.getWithoutQueryParameters(NetworkURLs.TWILIO_ACCESS_TOKEN, query: ["agentId":providerCode], headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let userToken = try decoder.decode(TwilioAccessResponse.self, from: responseData)
                completion(userToken, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func getWorkerStatus(_ workerSID:String, completion: @escaping WorkerStatuesCompletion) {
        BaseService.getWithoutQueryParameters(NetworkURLs.GET_WORKER_STATUS, query: ["WorkerSid":workerSID], headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let userToken = try decoder.decode(WorkerStatusModel.self, from: responseData)
                completion(userToken, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func setNewWorkerStatus(_ workerSID:String, status:String, completion: @escaping WorkerStatuesCompletion) {
        //?agentId=zq207
        BaseService.getWithoutQueryParameters(NetworkURLs.SET_WORKER_STATUS, query: ["WorkerSid":workerSID, "Status": status], headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let userToken = try decoder.decode(WorkerStatusModel.self, from: responseData)
                completion(userToken, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func getListOfActiveTasks(completion: @escaping ActiveTaskCompletion) {
        BaseService.post(NetworkURLs.GET_TASK_LIST, query: nil, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let userToken = try decoder.decode([ActiveTask].self, from: responseData)
                completion(userToken, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func addToCall(_ member:ActiveTask, callSID:String, toNumber:String, callDirection:String, completion: @escaping AddToCallResponse) {
        let fromNumber = self.defaultPhoneNumber
        let currentAgent = self.userProfile?.providerCode ?? ""
        let bodyParams = [
            "Queue":member.taskQueue ?? "",
            "CallSid":callSID,
            "AgentNumber":fromNumber,
            "CustomerNumber": toNumber,
            "CurrentAgent":currentAgent,
            "Direction":callDirection
        ]
        
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)
        let requestHeaders = ["Content-Type":"application/json"]
        
        BaseService.post(NetworkURLs.ADD_MEMBER_TO_CALL, query: nil, headers: requestHeaders, body: bodyData) { (dictionary, error, data) in
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
    
    
    func getPatientDetails(with providerCode:String, callSID:String, completion: @escaping PatientDetailResponse) {
        let bodyParams = ["ProviderCode":providerCode, "CallSid":callSID]
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)

        let requestHeaders = ["Content-Type":"application/json"]

        BaseService.post(NetworkURLs.GET_PATIENT_DETAILS, query: nil, headers: requestHeaders, body: bodyData) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(PatientDetails.self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func searchPatient(_ searchtext:String, completion: @escaping PatientSearchResponse) {
        let params = ["Id":searchtext.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? searchtext]
        BaseService.getWithoutQueryParameters(NetworkURLs.SEARCH_PATIENTS, query: params, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let object = try decoder.decode(SearchedPatient.self, from: responseData)
                completion(object, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    
    func getUserFromNumbers(_ providerCode:String, completion: @escaping ActiveTaskCompletion) {
        let params = ["ProviderCode":providerCode]

        BaseService.getWithoutQueryParameters(NetworkURLs.FROM_NUMBER, query: params, headers: nil, body: nil) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let userToken = try decoder.decode([ActiveTask].self, from: responseData)
                completion(userToken, nil)
            } catch let error {
                print(error)
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    
    func copyCallTaskToTasks(with providerCode:String, callSID:String, direction:String, completion: @escaping PatientDetailResponse) {
        let bodyParams = ["ProviderCode":providerCode, "CallSid":callSID, "CallDirection":direction]
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)

        let requestHeaders = ["Content-Type":"application/json"]

        BaseService.post(NetworkURLs.COPY_CALLTASKS_TO_TASK, query: nil, headers: requestHeaders, body: bodyData) { (dictionary, error, data) in
            guard let responseData = data else {
                completion(nil, "Received empty data in response.")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(PatientDetails.self, from: responseData)
                completion(responseObject, nil)
            } catch {
                completion(nil, "Unable to decode data successfully.")
            }
        }
    }
    
    func changePatientCallStatus(with type:String, callSID:String, direction:String, completion: @escaping HoldResumeResponse) {
        let bodyParams = ["CallSid":callSID, "Direction":direction]
        let bodyData = try? JSONSerialization.data(withJSONObject: bodyParams, options: .fragmentsAllowed)

        let requestHeaders = ["Content-Type":"application/json"]
        
        let completeURL = type == "hold" ? NetworkURLs.HOLD_IN_PROGRESS_CALL : NetworkURLs.RESUME_IN_PROGRESS_CALL

        BaseService.post(completeURL, query: nil, headers: requestHeaders, body: bodyData) { (dictionary, error, data) in
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
