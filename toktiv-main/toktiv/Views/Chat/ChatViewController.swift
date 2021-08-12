//
//  ChatViewController.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 10/08/2021.
//

import UIKit
import TwilioChatClient

class ChatViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var topLabel:UILabel!
    @IBOutlet weak var sendButton:UIButton!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var inputTextField:UITextField!
    @IBOutlet weak var bottomMarginConstraint:NSLayoutConstraint!
    
    var toEmpID = ""
    
    var toName = ""
    
    var channelID = ""
    
    var _channel:TCHChannel!
    var channel:TCHChannel! {
        
        get {
            return _channel
        }
        
        set(channel) {
            
            _channel = channel
            title = _channel.friendlyName
            _channel.delegate = self
            
            joinChannel()
        }
    }
    
    var messages:Set<TCHMessage> = Set<TCHMessage>()
    var sortedMessages:[TCHMessage]!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView!.allowsSelection = false
        tableView!.separatorStyle = .none
        
        tableView.register(UINib(nibName: "FromCell", bundle: nil), forCellReuseIdentifier: "FromCell")
        tableView.register(UINib(nibName: "ToCell", bundle: nil), forCellReuseIdentifier: "ToCell")

        inputTextField.addTarget(self, action: #selector(ConvesationViewController.textFieldDidChange(_:)), for: .editingChanged)

        self.topLabel.text = toName
        
        self.addObservers()
        
        configuration()
    }
    
    func configuration()
    {
        setViewOnHold(onHold: true)

        if let toEmployeeID = Int(toEmpID), let employeeIDStr = StateManager.shared.loginViewModel.userProfile?.employeeID, let employeeID = Int(employeeIDStr)
        {
            channelID = toEmployeeID < employeeID ? "\(employeeID)\(toEmployeeID)" : "\(toEmployeeID)\(employeeID)"
            ChannelManager.sharedManager.joinChatRoomWith(name: channelID)
            { (success) in
                
                if success
                {
                    self.channel = ChannelManager.sharedManager.currentChannel
                    if ChannelManager.sharedManager.currentChannel.synchronizationStatus == .all
                    {
                        self.loadMessages()
                        self.setViewOnHold(onHold: true)
                    }
                    else
                    {
                        
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
            inputTextField.resignFirstResponder()
            sendMessage(inputMessage: message)
        }
    }
    
    //MARK: - Helpers
    

    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func getConverstaion() {
        
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
    
    
    func joinChannel() {
        setViewOnHold(onHold: true)
        
        if channel.status != .joined {
            channel.join { result in
                print("Channel Joined")
            }
            return
        }
        
        loadMessages()
        setViewOnHold(onHold: false)
    }
    
    // Disable user input and show activity indicator
    func setViewOnHold(onHold: Bool) {
        self.inputTextField.isHidden = onHold;
        UIApplication.shared.isNetworkActivityIndicatorVisible = onHold;
    }
}

extension ChatViewController
{
    // MARK: - Chat Service
    
    func sendMessage(inputMessage: String) {
        let messageOptions = TCHMessageOptions().withBody(inputMessage)
        channel.messages?.sendMessage(with: messageOptions, completion: { (result, message) in
            self.inputTextField.text = ""
            self.inputTextField.resignFirstResponder()
        })
    }
    
    func addMessages(newMessages:Set<TCHMessage>) {
        messages =  messages.union(newMessages)
        sortMessages()
        DispatchQueue.main.async {
            self.tableView!.reloadData()
            if self.messages.count > 0 {
                self.scrollToBottom()
            }
        }
    }
    
    func sortMessages() {
        sortedMessages = messages.sorted { (a, b) -> Bool in
            (a.dateCreated ?? "") < (b.dateCreated ?? "")
        }
    }
    
    func loadMessages() {
        messages.removeAll()
        if channel.synchronizationStatus == .all {
            channel.messages?.getLastWithCount(100) { (result, items) in
                self.addMessages(newMessages: Set(items!))
            }
        }
    }
    
    func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count > 0 ? messages.count-1 : 0, section: 0)
            tableView!.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func leaveChannel() {
        channel.leave { result in
            if (result.isSuccessful()) {
                
            }
        }
    }
}


extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = sortedMessages[indexPath.row]

        let date = NSDate.dateWithISO8601String(dateString: message.dateCreated ?? "")
        let timestamp = DateTodayFormatter().stringFromDate(date: date)
        
        if message.author == StateManager.shared.loginViewModel.userProfile?.providerCode
        {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: "ToCell") as? ToCell {
                cell.messageLabel.text = message.body ?? ""
                cell.timeLabel.text = timestamp
                return cell
            }
        }
        else {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: "FromCell") as? FromCell {
                cell.messageLabel.text = message.body ?? ""
                cell.timeLabel.text = timestamp
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let string = sortedMessages[indexPath.row].body ?? ""
        let height = string.height(withConstrainedWidth: self.tableView.bounds.width - 120, font: UIFont.systemFont(ofSize: 15))
        return height + 50 + 21
    }
    
}

extension ChatViewController : TCHChannelDelegate {
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, messageAdded message: TCHMessage) {
        
        if !messages.contains(message) {
            addMessages(newMessages: [message])
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberJoined member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberLeft member: TCHMember) {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        DispatchQueue.main.async {
            if channel == self.channel {
                
            }
        }
    }
    
    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        if status == .all {
            loadMessages()
            DispatchQueue.main.async {
                self.tableView?.reloadData()
                self.setViewOnHold(onHold: false)
            }
        }
    }
}
