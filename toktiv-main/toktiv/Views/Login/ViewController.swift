//
//  ViewController.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import UIKit
import MBProgressHUD
import TwilioVoice
import NotificationBannerSwift
import SafariServices

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    
    var timer = Timer()
    var expDate:Date? = nil
    var stateManager = StateManager.shared
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let dataToken = UserDefaults.standard.data(forKey: AppConstants.USER_ACCESS_TOKEN), let _ = try? JSONDecoder().decode(LoginTokenModel.self, from: dataToken),  let dataProfile = UserDefaults.standard.data(forKey: AppConstants.USER_PROFILE_MODEL), let userProfileModel = try? JSONDecoder().decode(LoginUserModel.self, from: dataProfile) {
            
            if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = userProfileModel.twillioToken {
                
                self.handleAccessTokenExpiry(validAccessToken)
                
                TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData) { (error) in
                    if let error = error {
                        NSLog("LOGIN: An error occurred while registering: \(error.localizedDescription)")
                    } else {
                        NSLog("LOGIN: Successfully registered for VoIP push notifications.")
                    }
                }
            }
            
//            self.stateManager.setupWorkerStatus(userProfileModel.twilioClientStatus ?? "")
            self.stateManager.loginViewModel.userProfile = userProfileModel
            self.stateManager.loginViewModel.defaultPhoneNumber = self.stateManager.loginViewModel.userProfile?.twilioNum ?? ""
            
            MessagingManager.sharedManager().connectClientWithCompletion { (success, error) in
                
            }
            
            // Navigate to Dashboard
            self.moveToDashbnoard(animated: false)

        }
        
        usernameTextField.text = "zeeqa"
        passwordTextField.text = "apss20202021"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    //MARK: - IBActions
    @IBAction func loginButtonPressed(_ sender:UIButton) {
        
        guard let username = self.usernameTextField.text, username.count > 1 else {
            NotificationBanner(title: nil, subtitle: "Please enter valid Username.", leftView: nil, rightView: nil, style: .warning, colors: nil).show()
            return
        }
        guard let password = self.passwordTextField.text, password.count > 1 else {
            NotificationBanner(title: nil, subtitle: "Please enter valid Password.", leftView: nil, rightView: nil, style: .warning, colors: nil).show()
            return
        }
        
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        stateManager.loginViewModel.getAccessToken(with: username, password: password) { (response, error) in
            DispatchQueue.main.async {
                if let validResponse = response, let validToken = validResponse.accessToken, let dataObject = try? JSONEncoder().encode(validResponse) {
                    
                    UserDefaults.standard.setValue(dataObject, forKey: AppConstants.USER_ACCESS_TOKEN)
                    UserDefaults.standard.synchronize()
                    
                    self.stateManager.loginViewModel.getUserProfile(with: validToken, username: username, password: password) { (response, error) in
                        
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if let validResponse = response {
                            
                            if let dataObject = try? JSONEncoder().encode(validResponse) {
                                UserDefaults.standard.setValue(dataObject, forKey: AppConstants.USER_PROFILE_MODEL)
                                UserDefaults.standard.synchronize()
                            }
                            
                            if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = validResponse.twillioToken {
                                
                                self.handleAccessTokenExpiry(validAccessToken)
                                
                                TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData) { (error) in
                                    if let error = error {
                                        NSLog("LOGIN: An error occurred while registering: \(error.localizedDescription)")
                                    } else {
                                        NSLog("LOGIN: Successfully registered for VoIP push notifications.")
                                        StateManager.shared.accessToken = validAccessToken
                                    }
                                }
                            }
                            
                            
                            MessagingManager.sharedManager().connectClientWithCompletion { (success, error) in
                                
                            }
                            
                            self.stateManager.setupWorkerStatus(validResponse.twilioClientStatus ?? "")
                            self.stateManager.loginViewModel.userProfile = validResponse
                            self.stateManager.loginViewModel.defaultPhoneNumber = self.stateManager.loginViewModel.userProfile?.twilioNum ?? ""
                            self.moveToDashbnoard(animated: true)
                        }
                        else {
                            NotificationBanner(title: nil, subtitle: "Unable to login, Please try again", leftView: nil, rightView: nil, style: .danger, colors: nil).show()
                        }
                    }
                }
                else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    // error
                    NotificationBanner(title: nil, subtitle: "Login Failed: \(response?.error ?? "Something went wrong")", leftView: nil, rightView: nil, style: .danger, colors: nil).show()
                }
            }
        }
    }
    
    
    //MARK: - Helper Functions
    
    func handleAccessTokenExpiry(_ accessToken:String) {
        let jwtDictionary = JWTDecoder.decode(jwtToken: accessToken)
        if let exp = jwtDictionary["exp"] as? Double {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.expiryDate = Date(timeIntervalSince1970: exp)
//                 delegate.expiryDate =  Date().addingTimeInterval(60*5)
            }
        }
    }
    
    @objc func refreshToken() {
        print("refreshToken")
    }
    
    @objc func updateCounting() {
        if let validExpDate = self.expDate {
            let expDate = validExpDate.toLocalTime()
            let currentDate = Date().toLocalTime()
            
            if expDate <= currentDate {
                let providerCode = self.stateManager.loginViewModel.userProfile?.providerCode ?? ""
                self.stateManager.loginViewModel.getTwilioAccessToken(providerCode) { (respose, error) in
                    if let validAccessToken = respose?.token, let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken) {
                        print("Valid Refresh Token: \(validAccessToken)")
                        TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData) { (error) in
                            if let error = error {
                                NSLog("LOGIN: An error occurred while registering: \(error.localizedDescription)")
                            } else {
                                NSLog("LOGIN: Successfully registered for VoIP push notifications.")
                                self.expDate = Date().addingTimeInterval(60*60)
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func moveToDashbnoard(animated:Bool) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "DashbaordViewController") as? DashbaordViewController {
            self.navigationController?.pushViewController(controller, animated: animated)
        }
    }
    
    //MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.usernameTextField.isFirstResponder {
            self.passwordTextField.becomeFirstResponder()
        }
        else if self.passwordTextField.isFirstResponder {
            self.loginButtonPressed(UIButton())
        }
        return true
    }
}
