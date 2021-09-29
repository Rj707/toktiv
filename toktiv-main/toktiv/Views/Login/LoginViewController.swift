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

class LoginViewController: UIViewController, UITextFieldDelegate
{
    
    @IBOutlet weak var usernameTextField:UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    
    var timer = Timer()
    var expDate:Date? = nil
    var stateManager = StateManager.shared
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setupFlow()
        
        #if DEBUG
        usernameTextField.text = "Sameer"
        passwordTextField.text = "apss2021"
        passwordTextField.isSecureTextEntry = false
        #endif
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    //MARK: - Helper Functions
    
    func setupFlow()
    {
        if let dataToken = UserDefaults.standard.data(forKey: AppConstants.USER_ACCESS_TOKEN), let _ = try? JSONDecoder().decode(LoginTokenModel.self, from: dataToken),  let dataProfile = UserDefaults.standard.data(forKey: AppConstants.USER_PROFILE_MODEL), let userProfileModel = try? JSONDecoder().decode(LoginUserModel.self, from: dataProfile)
        {
            if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = userProfileModel.twillioToken
            {
                self.handleAccessTokenExpiry(validAccessToken)
                
                self.registerAtTwilioVoiceWith(accessToken: validAccessToken, andDeviceToken: validDeviceData)
            }
            
            self.stateManager.loginViewModel.userProfile = userProfileModel
            
            self.stateManager.loginViewModel.defaultPhoneNumber = self.stateManager.loginViewModel.userProfile?.twilioNum ?? ""
            
            self.connectTwilioChatClient()
            
            // Navigate to Dashboard
            self.moveToDashbnoard(animated: false)
        }
    }
    
    func handleAccessTokenExpiry(_ accessToken:String)
    {
        let jwtDictionary = JWTDecoder.decode(jwtToken: accessToken)
        if let exp = jwtDictionary["exp"] as? Double
        {
            if let delegate = UIApplication.shared.delegate as? AppDelegate
            {
                delegate.expiryDate = Date(timeIntervalSince1970: exp)
            }
        }
    }
    
    @objc func refreshToken()
    {
        print("refreshToken")
    }
    
    @objc func updateCounting()
    {
        if let validExpDate = self.expDate
        {
            let expDate = validExpDate.toLocalTime()
            let currentDate = Date().toLocalTime()
            
            if expDate <= currentDate
            {
                let providerCode = self.stateManager.loginViewModel.userProfile?.providerCode ?? ""
                
                self.stateManager.loginViewModel.getTwilioAccessToken(providerCode)
                { (respose, error) in
                    
                    if let validAccessToken = respose?.token, let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken)
                    {
                        print("Valid Refresh Token: \(validAccessToken)")
                        
                        self.registerAtTwilioVoiceWith(accessToken: validAccessToken, andDeviceToken: validDeviceData)
                    }
                }
            }
        }
    }
    
    func moveToDashbnoard(animated:Bool)
    {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "DashbaordViewController") as? DashbaordViewController
        {
            self.navigationController?.pushViewController(controller, animated: animated)
        }
    }
    
    //MARK: - IBActions
    
    @IBAction func loginButtonPressed(_ sender:UIButton)
    {
        guard let username = self.usernameTextField.text, username.count > 1
        else
        {
            NotificationBanner(title: nil, subtitle: "Please enter valid Username.", leftView: nil, rightView: nil, style: .warning, colors: nil).show()
            return
        }
        guard let password = self.passwordTextField.text, password.count > 1
        else
        {
            NotificationBanner(title: nil, subtitle: "Please enter valid Password.", leftView: nil, rightView: nil, style: .warning, colors: nil).show()
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        self.loginUserWith(username: username, password: password)
    }
    
    //MARK: - APIs
    
    func loginUserWith(username: String, password: String)
    {
        stateManager.loginViewModel.getAccessToken(with: username, password: password)
        { (response, error) in
            
            DispatchQueue.main.async
            {
                if let validResponse = response, let validToken = validResponse.accessToken, let dataObject = try? JSONEncoder().encode(validResponse)
                {
                    
                    UserDefaults.standard.setValue(dataObject, forKey: AppConstants.USER_ACCESS_TOKEN)
                    UserDefaults.standard.synchronize()
                    
                    self.getUserProfileAgainstAccessToken(validToken: validToken, username: username, password: password)
                }
                else
                {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    // error
                    NotificationBanner(title: nil, subtitle: "Login Failed: \(response?.error ?? "Something went wrong")", leftView: nil, rightView: nil, style: .danger, colors: nil).show()
                }
            }
        }
    }
    
    func getUserProfileAgainstAccessToken(validToken: String, username: String, password: String)
    {
        self.stateManager.loginViewModel.getUserProfile(with: validToken, username: username, password: password)
        { (response, error) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let validResponse = response
            {
                if let dataObject = try? JSONEncoder().encode(validResponse)
                {
                    UserDefaults.standard.setValue(dataObject, forKey: AppConstants.USER_PROFILE_MODEL)
                    UserDefaults.standard.synchronize()
                }
                
                if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = validResponse.twillioToken
                {
                    self.handleAccessTokenExpiry(validAccessToken)
                    
                    self.registerAtTwilioVoiceWith(accessToken: validAccessToken, andDeviceToken: validDeviceData)
                }
                
                self.connectTwilioChatClient()
                
                self.stateManager.setupWorkerStatus(validResponse.twilioClientStatus ?? "")
                self.stateManager.loginViewModel.userProfile = validResponse
                self.stateManager.loginViewModel.defaultPhoneNumber = self.stateManager.loginViewModel.userProfile?.twilioNum ?? ""
                self.moveToDashbnoard(animated: true)
            }
            else
            {
                NotificationBanner(title: nil, subtitle: "Unable to login, Please try again", leftView: nil, rightView: nil, style: .danger, colors: nil).show()
            }
        }
    }

    //MARK: - Twilio
    
    func registerAtTwilioVoiceWith(accessToken: String, andDeviceToken deviceToken: Data)
    {
        TwilioVoice.register(accessToken: accessToken, deviceToken: deviceToken)
        { (error) in
            
            if let error = error
            {
                NSLog("LOGIN: An error occurred while registering: \(error.localizedDescription)")
            }
            else
            {
                NSLog("LOGIN: Successfully registered for VoIP push notifications.")
            }
        }
    }
    
    func connectTwilioChatClient()
    {
        MessagingManager.sharedManager().connectClientWithCompletion
        { (success, error) in
            
            if success
            {
                self.registerTwilioChatClientWithDeviceToken()
            }
            else
            {
                NotificationBanner(title: nil, subtitle: "LoginViewController: An error occurred at connectClientWithCompletion: \(error?.localizedDescription ?? "")", leftView: nil, rightView: nil, style: .danger, colors: nil).show()
            }
        }
    }
    
    func registerTwilioChatClientWithDeviceToken()
    {
        MessagingManager.sharedManager().registerChatClientWith(deviceToken: (UIApplication.shared.delegate as! AppDelegate).updatedPushToken ?? Data.init())
        { (success) in
            
            if success
            {
            }
            else
            {
                NotificationBanner(title: nil, subtitle: "LoginViewController: An error occurred at registerTwilioChatClientWithDeviceToken:", leftView: nil, rightView: nil, style: .danger, colors: nil).show()
            }
        }
    }
    
    //MARK: - TextField Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if self.usernameTextField.isFirstResponder
        {
            self.passwordTextField.becomeFirstResponder()
        }
        else if self.passwordTextField.isFirstResponder
        {
            self.loginButtonPressed(UIButton())
        }
        return true
    }
}
