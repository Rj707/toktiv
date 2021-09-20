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
        var title = ""
        if let bestAttemptContent = bestAttemptContent {
            
            var contactList = [ChatUserModel]()
            if let contactListData = DataManager.shared.contactList {
                title += "1"
//                if let list = try? JSONDecoder().decode([ChatUserModel].self, from: contactListData) {
//                    title += "2"

                    contactList = contactListData
//                }
            }
            
            if contactList.count > 0
            {
                title += "2"
                
            }
            
            let apsData = request.content.userInfo["aps"] as! [String : Any]
            let alertData = apsData["alert"] as! [String : Any]
            if var alertBody  = (alertData["body"] as? String), alertBody.count > 0
            {
                title += "3"

                let userName = alertBody.components(separatedBy: "You have a new message from")[1]
                contactList = contactList.filter({ (chatUserModel) -> Bool in
                    return chatUserModel.providerCode == userName.trimmingCharacters(in: .whitespaces)
                })
                var contact : ChatUserModel?
                if contactList.count > 0
                {
                    title += "4"
                    contact = contactList[0]
                    alertBody = alertBody.replacingOccurrences(of: userName, with: " \(contact?.providerName ?? "Not found")")
                }
//                for contact in contactList {
//                    title += "4"
//
//                    if userName.trimmingCharacters(in: .whitespaces) == contact.providerCode {
//                        title += "5"
//                        alertBody = alertBody.replacingOccurrences(of: userName, with: " \(contact.providerName ?? "")")
//                    }
//                }
                bestAttemptContent.body = alertBody
            }
            bestAttemptContent.title = (alertData["title"] as? String) ?? title
            
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
