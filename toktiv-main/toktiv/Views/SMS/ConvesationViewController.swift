//
//  ConvesationViewController.swift
//  toktiv
//
//  Created by Developer on 23/11/2020.
//

import UIKit
import MBProgressHUD
import GrowingTextView

class ConvesationViewController: UIViewController, GrowingTextViewDelegate {
    
    @IBOutlet weak var topLabel:UILabel!
    @IBOutlet weak var sendButton:UIButton!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var inputTextView:GrowingTextView!
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
        
        self.topLabel.text = self.topName
        
        self.addObservers()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        configureInputTextView()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGestureRecognizer)
        tableView.keyboardDismissMode = .interactive
    }
    
    func configureInputTextView()
    {
        automaticallyAdjustsScrollViewInsets = false
        
        inputTextView.maxLength = 1000
        inputTextView.trimWhiteSpaceWhenEndEditing = false
        inputTextView.placeholderColor = UIColor(white: 0.8, alpha: 1.0)
        inputTextView.minHeight = 25.0
        inputTextView.maxHeight = 100.0
        inputTextView.backgroundColor = UIColor.white
        inputTextView.layer.cornerRadius = 4.0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        inputTextView.text = StateManager.shared.getDraftMessage(self.selectedChat?.from ?? "")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        let draftMessage = DraftMessageModel(channelId: self.selectedChat?.from ?? "", message: inputTextView.text)
        StateManager.shared.saveDraftMessage(draftMessage)
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
        if let message = self.inputTextView.text {
            let accessToken = self.observer.loginViewModel.userAccessToken
            let from = self.observer.loginViewModel.defaultPhoneNumber
            let to = self.toNumber
            self.view.endEditing(true)
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.observer.userHistoryViewModel.sendMessage(accessToken, message: message, from: from, to: to) { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let res = response?.res, res == 1 {
                    self.inputTextView.text = ""
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
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        // Subscribe to Keyboard Will Hide notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
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
    
//    @objc func keyboardDidAppear(notification: NSNotification) {
//        let keyboardSize:CGSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
//        let height = min(keyboardSize.height, keyboardSize.width)
//        UIView.animate(withDuration: 0.3) {
//            DispatchQueue.main.async {
//                var value = 0
//                if let window = UIApplication.shared.windows.first {
//                    value = Int(window.safeAreaInsets.bottom)
//                }
//                self.bottomMarginConstraint.constant = height - CGFloat(value)
//                self.view.layoutIfNeeded()
//            }
//        }
//    }
//
//    @objc func keyboardWillHide(notification: NSNotification) {
//        print("Keyboard hidden")
//        UIView.animate(withDuration: 0.3) {
//            DispatchQueue.main.async {
//                self.bottomMarginConstraint.constant = 0
//                self.view.layoutIfNeeded()
//            }
//        }
//    }
    
    @objc dynamic func keyboardWillShow(_ notification: NSNotification)
    {
        animateWithKeyboard(notification: notification)
        { (keyboardFrame) in
            
            let constant = keyboardFrame.height
            var value = 0
            if let window = UIApplication.shared.windows.first
            {
                value = Int(window.safeAreaInsets.bottom)
            }
            self.bottomMarginConstraint?.constant = constant - CGFloat(value)
            self.tableView.scrollToBottom()
        }
    }
        
    @objc dynamic func keyboardWillHide(_ notification: NSNotification)
    {
        animateWithKeyboard(notification: notification)
        { (keyboardFrame) in
            
            self.bottomMarginConstraint?.constant = 0
        }
    }
    
    @objc func closeKeyboard()
    {
        inputTextView.endEditing(true)
    }
    
  
    //MARK: - UITextView
    
    func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat)
    {
           UIView.animate(withDuration: 0.2)
           {
               self.view.layoutIfNeeded()
           }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    {
        return true
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        let haveText = textView.text?.count ?? 0 > 0
        self.sendButton.isSelected = haveText
        self.sendButton.isUserInteractionEnabled = haveText
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
