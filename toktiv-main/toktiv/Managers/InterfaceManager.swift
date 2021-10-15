//
//  InterfaceManager.swift
//  toktiv
//
//  Created by Hafiz Saad on 02/10/2021.
//

import UIKit
import MBProgressHUD

class InterfaceManager: NSObject
{
    static let shared = InterfaceManager()
    var isHudAlreadyAdded = false

    private override init() { }
    
    func showLoader()
    {
        if !isHudAlreadyAdded
        {
            DispatchQueue.main.async
            {
                MBProgressHUD.showAdded(to: UIApplication.shared.topMostViewController()?.view ?? UIView.init(), animated: true)
            }
            isHudAlreadyAdded = true
        }
    }
    
    func hideLoader()
    {
        if isHudAlreadyAdded
        {
            isHudAlreadyAdded = false
        }
        DispatchQueue.main.async
        {
            MBProgressHUD.hide(for: UIApplication.shared.topMostViewController()?.view ?? UIView.init(), animated: true)
        }
    }
    
    func showAlertWithTitle(title:String?, message:String?,completionHandler handler: @escaping () -> Void)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default)
        { _ in
            
            handler()
        })
        DispatchQueue.main.async
        {
            UIApplication.shared.topMostViewController()?.present(alert, animated: true){}
        }
    }
}
