//
//  SettingsViewController.swift
//  toktiv
//
//  Created by Developer on 01/12/2020.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var secondsCountLabel:UILabel!
    @IBOutlet weak var stepper:UIStepper!
    
    var currentCount:Int {
        set {
            self.secondsCountLabel.text = "Next Inbound Call Time: \(newValue) secs"
            UserDefaults.standard.set(newValue, forKey: AppConstants.WAIT_TIME_IN_SECONDS)
            UserDefaults.standard.synchronize()
        }
        
        get {
            return UserDefaults.standard.integer(forKey: AppConstants.WAIT_TIME_IN_SECONDS)
        }
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.secondsCountLabel.text = "Next Inbound Call Time: \(self.currentCount) secs"
        self.stepper.value = Double(self.currentCount)
    }
    
    //MARK: - IBActions
    @IBAction func updateSecondCount(_ sender:UIStepper) {
        self.currentCount = Int(sender.value)
    }
    
    @IBAction func popThisController() {
        self.navigationController?.popViewController(animated: true)
    }
}
