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

extension UIView
{
    @IBInspectable var cornerRadius: CGFloat
    {
        get
        {
            return layer.cornerRadius
        }
        set
        {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat
    {
        get
        {
            return layer.borderWidth
        }
        set
        {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor?
    {
        get
        {
            return UIColor(cgColor: layer.borderColor!)
        }
        set
        {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat
    {
        get
        {
            return layer.shadowRadius
        }
        set
        {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float
    {
        get
        {
            return layer.shadowOpacity
        }
        set
        {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize
    {
        get
        {
            return layer.shadowOffset
        }
        set
        {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor?
    {
        get
        {
            if let color = layer.shadowColor
            {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set
        {
            if let color = newValue
            {
                layer.shadowColor = color.cgColor
            }
            else
            {
                layer.shadowColor = nil
            }
        }
    }
}

extension UIImageView {

func setImageTintColor(_ color: UIColor) {
    let tintedImage = self.image?.withRenderingMode(.alwaysTemplate)
    self.image = tintedImage
    self.tintColor = color
  }
}

extension UIColor
{
   static func hexStringToUIColor (hex:String) -> UIColor
   {
       var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
       
       if (cString.hasPrefix("#"))
       {
           cString.remove(at: cString.startIndex)
       }
       
       if ((cString.count) != 6)
       {
           return UIColor.gray
       }
       
       var rgbValue:UInt32 = 0
       Scanner(string: cString).scanHexInt32(&rgbValue)
       
       return UIColor(
           red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
           green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
           blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
           alpha: CGFloat(1.0)
       )
   }
}

extension UIViewController
{
    func animateWithKeyboard(notification: NSNotification, animations: ((_ keyboardFrame: CGRect) -> Void)?)
    {
        // Extract the duration of the keyboard animation
        let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        let duration = notification.userInfo![durationKey] as! Double
        
        // Extract the final frame of the keyboard
        let frameKey = UIResponder.keyboardFrameEndUserInfoKey
        let keyboardFrameValue = notification.userInfo![frameKey] as! NSValue
        
        // Extract the curve of the iOS keyboard animation
        let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
        let curveValue = notification.userInfo![curveKey] as! Int
        let curve = UIView.AnimationCurve(rawValue: curveValue)!
        
        // Create a property animator to manage the animation
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve)
        {
            // Perform the necessary animation layout updates
            animations?(keyboardFrameValue.cgRectValue)
            
            // Required to trigger NSLayoutConstraint changes to animate
            self.view?.layoutIfNeeded()
        }
        
        // Start the animation
        animator.startAnimation()
    }
}
