//
//  CallSessionManager.swift
//  toktiv
//
//  Created by Developer on 03/12/2020.
//

import UIKit
import NotificationBannerSwift
import TwilioVoice

class CallSessionManager: NSObject {
    
    static let shared = CallSessionManager()
    
    var observer = StateManager.shared
    var banner:StatusBarNotificationBanner? = nil
    var tryCount = 5
    
    var suspensionTimer:Timer? = nil

    var lastInboundCallDate:Date? {
        let date = UserDefaults.standard.object(forKey: AppConstants.LAST_INBOUND_CALL_DATE) as? Date
        return date
    }
    
    var defaultSecondsForSuspension:Int {
        return UserDefaults.standard.integer(forKey: AppConstants.WAIT_TIME_IN_SECONDS)
    }
    
    var secondsSinceLastCall:Int {
        if let validDate = self.lastInboundCallDate {
            let distance = validDate.distance(to: Date())
            return Int(distance)
        }
        
        return 0
    }
    
    var secondsLeft:Int {
        return self.defaultSecondsForSuspension - self.secondsSinceLastCall
    }
    
    func startSuspensionTimer() {
        if UIApplication.shared.applicationState == .active {
            self.banner?.dismiss()
            self.banner?.remove()
            suspensionTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            
            self.banner = StatusBarNotificationBanner(title: "Suspending Inbound Calls...", style: .warning, colors: nil)
            self.banner?.autoDismiss = false
            self.banner?.show()
            
            self.removeInboundCallAccessToken()
        }
        
    }
 
    func appComesInForeground() {
        if let _ = self.lastInboundCallDate, self.secondsSinceLastCall > 0, self.secondsSinceLastCall < self.defaultSecondsForSuspension {
            
            self.banner?.dismiss()
            self.banner?.remove()
            suspensionTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            
            self.banner = StatusBarNotificationBanner(title: "Inbounds calls suspended for \(self.secondsLeft)", style: .warning, colors: nil)
            self.banner?.autoDismiss = false
            self.banner?.show()
            
            self.removeInboundCallAccessToken()
        }
        else {
            clearUp(suspended: false)
        }
    }
    
    func clearUp(suspended:Bool = true) {
        
        self.suspensionTimer?.invalidate()
        self.suspensionTimer = nil
        self.banner?.dismiss()
        self.banner?.remove()
        if !suspended {
            UserDefaults.standard.removeObject(forKey: AppConstants.LAST_INBOUND_CALL_DATE)
            UserDefaults.standard.synchronize()
        }
    }
    
    func appGoesInBackground() {
        clearUp()
    }
    
    @objc func update() {
        self.banner?.titleLabel?.text = "Inbounds calls suspended for \(self.secondsLeft)"
        
        if self.secondsSinceLastCall >= self.defaultSecondsForSuspension {
            clearUp(suspended: false)
            addInboundCallAccessToken()
        }
    }
    
    func removeInboundCallAccessToken() {
        guard tryCount > 0 else {
            return
        }
        
        if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = self.observer.loginViewModel.userProfile?.twillioToken {
            TwilioVoice.unregister(accessToken: validAccessToken, deviceToken: validDeviceData) { (error) in
                if let _ = error {
                    self.tryCount -= 1
                    self.removeInboundCallAccessToken()
                    return
                }
                
                self.banner?.titleLabel?.text = "Inbounds calls suspended for \(self.secondsLeft)"
                print("**** unregister ****")
            }
        }
    }
    
    func addInboundCallAccessToken() {
        guard tryCount > 0 else {
            return
        }
        if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = self.observer.loginViewModel.userProfile?.twillioToken {
           
            TwilioVoice.register(accessToken: validAccessToken, deviceToken: validDeviceData) { (error) in
                if let _ = error {
                    self.tryCount -= 1
                    self.addInboundCallAccessToken()
                    return
                }
                
                self.banner?.dismiss()
                print("**** register ****")
            }
        }
    }
    
}
