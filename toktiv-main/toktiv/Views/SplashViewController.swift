//
//  SplashViewController.swift
//  toktiv
//
//  Created by Hafiz Saad on 02/10/2021.
//

import UIKit
import MBProgressHUD
import TwilioVoice
import NotificationBannerSwift
import SafariServices


class SplashViewController: UIViewController
{
    var stateManager = StateManager.shared
    
    @IBOutlet weak var imageView : UIImageView!

    override func viewDidLoad()
    {
        super.viewDidLoad()

        if let dataToken = UserDefaults.standard.data(forKey: AppConstants.USER_ACCESS_TOKEN), let _ = try? JSONDecoder().decode(LoginTokenModel.self, from: dataToken),  let dataProfile = UserDefaults.standard.data(forKey: AppConstants.USER_PROFILE_MODEL), let userProfileModel = try? JSONDecoder().decode(LoginUserModel.self, from: dataProfile)
        {
            if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = userProfileModel.twillioToken
            {
//                self.handleAccessTokenExpiry(validAccessToken)

                self.registerAtTwilioVoiceWith(accessToken: validAccessToken, andDeviceToken: validDeviceData)
            }

            self.stateManager.loginViewModel.userProfile = userProfileModel

            self.stateManager.loginViewModel.defaultPhoneNumber = self.stateManager.loginViewModel.userProfile?.twilioNum ?? ""

            self.connectTwilioChatClient()
            
            NotificationCenter.default.addObserver(self, selector: #selector(onCompletedChannelsList(_:)), name: NSNotification.Name.init("kChannelsListCompleted"), object: nil)
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5
                , execute:
            {
                self.animate()
            })
        }
        
    }
    
    @objc func onCompletedChannelsList(_ notification: Notification)
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init("kChannelsListCompleted"), object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5
            , execute:
        {
            self.animate()
        })
        
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        imageView.center = view.center
    }
    
    private func animate()
    {
//        UIView.animate(withDuration: 1, animations:
//        {
//            let size = self.view.frame.width * 3
//            let diffX  = size - self.view.frame.size.width
//            let diffY = self.view.frame.size.height - size
//
//            self.imageView.frame = CGRect(x: -(diffX/2), y: diffY/2, width: size, height: size)
//            self.imageView.alpha = 0
//        })
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.6, execute:
        {
            let home = self.storyboard?.instantiateViewController(withIdentifier: "LoginNavigationController") as! UINavigationController
            home.modalTransitionStyle = .crossDissolve
            home.modalPresentationStyle = .fullScreen
            self.present(home, animated: true)
        })
        
        
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
//                self.registerTwilioChatClientWithDeviceToken()
            }
            else
            {
                NotificationBanner(title: "", subtitle: "LoginViewController: An error occurred at connectClientWithCompletionethod: \(error?.localizedDescription ?? "")", style: .danger).show()
            }
        }
    }
}
