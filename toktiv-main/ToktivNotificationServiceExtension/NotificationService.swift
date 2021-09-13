//
//  NotificationService.swift
//  ToktivNotificationServiceExtension
//
//  Created by Hafiz Saad on 13/09/2021.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            let apsData = request.content.userInfo["aps"] as! [String : Any]
            let alertData = apsData["alert"] as! [String : Any]
            if var alertBody  = (alertData["body"] as? String), alertBody.count > 0
            {
                let userName = alertBody.components(separatedBy: "You have a new message from")[1]
                if userName.trimmingCharacters(in: .whitespaces) == "ZQ207" {
                    alertBody = alertBody.replacingOccurrences(of: userName, with: " Zeeqa")
                }
                bestAttemptContent.body = alertBody
            }
            bestAttemptContent.title = (alertData["title"] as? String) ?? ""
            
            contentHandler(bestAttemptContent)
            
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
