//
//  ConvesationViewController.swift
//  toktiv
//
//  Created by Developer on 23/11/2020.
//

import UIKit
import MBProgressHUD

class ConvesationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var topLabel:UILabel!
    @IBOutlet weak var sendButton:UIButton!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var inputTextField:UITextField!
    @IBOutlet weak var bottomMarginConstraint:NSLayoutConstraint!
    
    let toCellIdentifier = "ToCell"
    let fromCellIdentifier = "FromCell"
    var isFromPushNotificationPresent:Bool = false
    var observer = StateManager.shared
    var refreshControl = UIRefreshControl()
    var selectedChat:HistoryResponseElement?
    var currentMessages = [HistoryResponseElement]()
    var topName:String {
        if selectedChat?.direction?.lowercased() == "inbound" {
            if selectedChat?.fromName?.count ?? 0 > 0 {
                return selectedChat?.fromName ?? ""
            }
            
            if selectedChat?.from?.count ?? 0 > 0 {
                return selectedChat?.from ?? ""
            }
        }
        else {
            if selectedChat?.toName?.count ?? 0 > 0 {
                return selectedChat?.toName ?? ""
            }
            
            if selectedChat?.to?.count ?? 0 > 0 {
                return selectedChat?.to ?? ""
            }
        }
        
        return ""
    }
    
    var toNumber:String {
        if selectedChat?.direction?.lowercased() == "inbound" {
            if selectedChat?.from?.count ?? 0 > 0 {
                return selectedChat?.from ?? ""
            }
        }
        else {
            if selectedChat?.to?.count ?? 0 > 0 {
                return selectedChat?.to ?? ""
            }
        }
        
        return ""
    }

    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UINib(nibName: fromCellIdentifier, bundle: nil), forCellReuseIdentifier: fromCellIdentifier)
        self.tableView.register(UINib(nibName: toCellIdentifier, bundle: nil), forCellReuseIdentifier: toCellIdentifier)

        self.getConverstaion()
        
        inputTextField.addTarget(self, action: #selector(ConvesationViewController.textFieldDidChange(_:)), for: .editingChanged)

        self.topLabel.text = self.topName
        
        self.addObservers()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
    }

    
    //MARK: - IBActions
    @IBAction func popThisController() {
        if isFromPushNotificationPresent {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func sendMessage(_ sender:UIButton) {
        if let message = self.inputTextField.text {
            let accessToken = self.observer.loginViewModel.userAccessToken
            let from = self.observer.loginViewModel.defaultPhoneNumber
            let to = self.toNumber
            self.view.endEditing(true)
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.observer.userHistoryViewModel.sendMessage(accessToken, message: message, from: from, to: to) { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let res = response?.res, res == 1 {
                    self.inputTextField.text = ""
                    self.getConverstaion()
                }
                else {
                    self.showMessage(response?.data ?? "Unable to send message")
                }
            }
            
        }
    }
    
    //MARK: - Helpers
    
    @objc func refresh(_ sender: AnyObject) {
        
        if let validTo = self.selectedChat?.to, let validFrom = self.selectedChat?.from, let providerCode = self.observer.loginViewModel.userProfile?.providerCode {
            observer.userHistoryViewModel.getUserSMSHistory(providerCode: providerCode, from: validFrom , to: validTo, type: "conversation") { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.currentMessages.removeAll()
                self.currentMessages = response ?? []
                
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
                if self.currentMessages.count > 0 {
                    self.scrollToBottom()
                }
            }
        }
        else {
            self.refreshControl.endRefreshing()
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func getConverstaion() {
        if let validTo = self.selectedChat?.to, let validFrom = self.selectedChat?.from, let providerCode = self.observer.loginViewModel.userProfile?.providerCode {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            observer.userHistoryViewModel.getUserSMSHistory(providerCode: providerCode, from: validFrom , to: validTo, type: "conversation") { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.currentMessages.removeAll()
                self.currentMessages = response ?? []
                self.tableView.reloadData()
                if self.currentMessages.count > 0 {
                    self.scrollToBottom()
                }
            }
        }
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.currentMessages.count-1, section: 0)
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

extension ConvesationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = self.currentMessages[indexPath.row]
        if message.direction == "Outbound" {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: toCellIdentifier) as? ToCell {
                cell.smsRecord = message
                return cell
            }
        }
        else {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: fromCellIdentifier) as? FromCell {
                cell.smsRecord = message
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let string = self.currentMessages[indexPath.row].content ?? ""
        let height = string.height(withConstrainedWidth: self.tableView.bounds.width - 120, font: UIFont.systemFont(ofSize: 15))
        return height + 50 + 21
    }
}
