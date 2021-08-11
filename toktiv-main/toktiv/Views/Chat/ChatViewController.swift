//
//  ChatViewController.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 10/08/2021.
//

import UIKit

class ChatViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var topLabel:UILabel!
    @IBOutlet weak var sendButton:UIButton!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var inputTextField:UITextField!
    @IBOutlet weak var bottomMarginConstraint:NSLayoutConstraint!
    
    var toEmpID = ""
    
    var toName = ""
    
    var channelID = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        inputTextField.addTarget(self, action: #selector(ConvesationViewController.textFieldDidChange(_:)), for: .editingChanged)

        self.topLabel.text = toName
        
        self.addObservers()
        
        configuration()
    }
    
    func configuration()
    {
        if let toEmployeeID = Int(toEmpID), let employeeIDStr = StateManager.shared.loginViewModel.userProfile?.employeeID, let employeeID = Int(employeeIDStr)
        {
            channelID = toEmployeeID > employeeID ? "\(employeeID)\(toEmployeeID)" : "\(toEmployeeID)\(employeeID)"
            ChannelManager.sharedManager.joinChatRoomWith(name: channelID) { (success) in
                if success
                {
                    if ChannelManager.sharedManager.currentChannel.synchronizationStatus == .all {
                        ChannelManager.sharedManager.currentChannel.messages?.getLastWithCount(100) { (result, items) in
                            
                        }
                    }
                }
            }
        }
    }
    

    //MARK: - IBActions
    @IBAction func popThisController() {
        
            self.navigationController?.popViewController(animated: true)
        }
    
    @IBAction func sendMessage(_ sender:UIButton) {
        if let message = self.inputTextField.text {
            
        }
    }
    
    //MARK: - Helpers
    

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func getConverstaion() {
        
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    
    //MARK: - Keyboard Observers
    
    @objc func keyboardDidAppear(notification: NSNotification) {
        let keyboardSize:CGSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        let height = min(keyboardSize.height, keyboardSize.width)
        UIView.animate(withDuration: 0.3) {
            DispatchQueue.main.async {
                var value = 0
                if let window = UIApplication.shared.windows.first {
                    value = Int(window.safeAreaInsets.bottom)
                }
                self.bottomMarginConstraint.constant = height - CGFloat(value)
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        print("Keyboard hidden")
        UIView.animate(withDuration: 0.3) {
            DispatchQueue.main.async {
                self.bottomMarginConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
  
    //MARK: - TextField Handling
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let haveText = textField.text?.count ?? 0 > 0
        self.sendButton.isSelected = haveText
        self.sendButton.isUserInteractionEnabled = haveText
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}


extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let message = self.currentMessages[indexPath.row]
//        if message.direction == "Outbound" {
//            if let cell = self.tableView.dequeueReusableCell(withIdentifier: toCellIdentifier) as? ToCell {
//                cell.smsRecord = message
//                return cell
//            }
//        }
//        else {
//            if let cell = self.tableView.dequeueReusableCell(withIdentifier: fromCellIdentifier) as? FromCell {
//                cell.smsRecord = message
//                return cell
//            }
//        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let string = self.currentMessages[indexPath.row].content ?? ""
//        let height = string.height(withConstrainedWidth: self.tableView.bounds.width - 120, font: UIFont.systemFont(ofSize: 15))
        return 9//height + 50 + 21
    }
}
