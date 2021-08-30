//
//  Extensions.swift
//  Toktiv
//
//  Created by Developer on 11/12/2020.
//

import Foundation
import UIKit
import NotificationBannerSwift

extension UIViewController {
    func showMessage(_ message:String) {
        let alertController = UIAlertController(title: "TokTiv", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
        
        }))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension Date {

    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

public extension String {
    func isNumber() -> Bool {
        return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil && self.rangeOfCharacter(from: CharacterSet.letters) == nil
    }
}

//MARK:- Custom Notification Banner Colors Class

class CustomBannerColors: BannerColorsProtocol {

    internal func color(for style: BannerStyle) -> UIColor {
        switch style {
        case .danger:  return UIColor.red  // Your custom .danger color
        case .info: return #colorLiteral(red: 0.2392156863, green: 0.4705882353, blue: 0.8274509804, alpha: 1)   // Your custom .info color
        case .customView: return UIColor.yellow// Your custom .customView color
        case .success: return UIColor.green  // Your custom .success color
        case .warning: return UIColor.blue // Your custom .warning color
        }
    }

}
