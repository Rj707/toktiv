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
            DispatchQueue.main.async {
                MBProgressHUD.showAdded(to: UIApplication.shared.topMostViewController()?.view ?? UIView.init(), animated: true)
            }
            isHudAlreadyAdded = true
        }
    }
    
    func hideLoader()
    {
        if isHudAlreadyAdded
        {
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: UIApplication.shared.topMostViewController()?.view ?? UIView.init(), animated: true)
            }
            isHudAlreadyAdded = false
        }
    }
}
