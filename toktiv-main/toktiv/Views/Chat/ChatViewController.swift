//
//  ChatViewController.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 10/08/2021.
//

import UIKit
import TwilioChatClient
import MBProgressHUD
import MobileCoreServices
import NotificationBannerSwift
import GrowingTextView

enum ChatViewNavigation
{
    case Contacts
    case PUSH
}

class ChatViewController: UIViewController, UITextFieldDelegate, GrowingTextViewDelegate
{
    @IBOutlet weak var topLabel:UILabel!
    @IBOutlet weak var sendButton:UIButton!
    @IBOutlet weak var attachmentButton:UIButton!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var inputTextField:UITextField!
    @IBOutlet weak var bottomMarginConstraint:NSLayoutConstraint!
    @IBOutlet weak var chatInputView:UIView!
    @IBOutlet weak var viewAttachmentInfo: UIView!
    @IBOutlet weak var labelAttachmentName: UILabel!
    @IBOutlet weak var attachmentTypeImage: UIImageView!

    @IBOutlet weak var inputTextView:GrowingTextView!

    var navigation : ChatViewNavigation = .Contacts
    
    var toEmpID = ""
    
    var toName = ""
    
    var channelID = ""
    
    var channelSID = ""
        
    var _channel:TCHChannel!
    var channel:TCHChannel!
    {
        get
        {
            return _channel
        }
        
        set(channel)
        {
            _channel = channel
            title = _channel.friendlyName
            _channel.delegate = self
            
            joinChannel()
        }
    }
    
    var messages:Set<TCHMessage> = Set<TCHMessage>()
    var sortedMessages:[TCHMessage]!
    
    var attachmentName = ""
    var attachmentType = ""
    var attachmentData:Data!
    
    //MARK: - Implementation

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setup()
        
        addObservers()
        
        if navigation == .Contacts
        {
            joinOrCreateChannel()
        }
        else
        {
            let deadlineTime = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime)
            {
                self.loadChannelChatUponPush()
            }
        }
        
        configureInputTextView()
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
    
    func setup()
    {
        self.viewAttachmentInfo.isHidden = true
        self.view.layoutIfNeeded()
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        tableView!.allowsSelection = true
        tableView!.separatorStyle = .none
        
        tableView.register(UINib(nibName: "FromChatTableViewCell", bundle: nil), forCellReuseIdentifier: "FromChatTableViewCell")
        tableView.register(UINib(nibName: "ToChatTableViewCell", bundle: nil), forCellReuseIdentifier: "ToChatTableViewCell")

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGestureRecognizer)

        self.topLabel.text = toName
    }
    
    func joinOrCreateChannel()
    {
        setViewOnHold(onHold: true)

        if let toEmployeeID = Int(toEmpID), let employeeIDStr = StateManager.shared.loginViewModel.userProfile?.employeeID, let employeeID = Int(employeeIDStr)
        {
            channelID = toEmployeeID < employeeID ? "\(employeeID)\(toEmployeeID)" : "\(toEmployeeID)\(employeeID)"
            ChannelManager.sharedManager.joinChatRoomWith(name: channelID)
            { (success, error) in
                
                if success
                {
                    self.getConverstaion()
                }
                else
                {
                    DispatchQueue.main.async
                    {
                        let banner = NotificationBanner(title: "Error", subtitle: error?.localizedDescription, style: .danger)
                        banner.show()
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
        }
    }
    
    func loadChannelChatUponPush()
    {
        setViewOnHold(onHold: true)

        if self.channelSID != ""
        {
            ChannelManager.sharedManager.joinChatRoomWith(name: channelSID)
            { (success, error) in
                
                if success
                {
                    self.getConverstaion()
                }
                else
                {
                    if error?.localizedDescription == "An unexpected error occurred."
                    {
                        if ChannelManager.sharedManager.channelsList == nil
                        {
                            self.handleMessagingManagerConnectionError()
                        }
                    }
                    
                    DispatchQueue.main.async
                    {
                        let banner = NotificationBanner(title: "Error", subtitle: error?.localizedDescription, style: .danger)
                        banner.show()
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
        }
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
        self.sendButton.backgroundColor = haveText ? UIColor.systemGreen : UIColor.lightGray
        self.sendButton.isUserInteractionEnabled = haveText
    }
    

    //MARK: - IBActions
    
    @IBAction func popThisController()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendMessage(_ sender:UIButton)
    {
        if attachmentData != nil && attachmentData.count > 0
        {
            sendAttachment()
        }
        else
        {
            if let message = self.inputTextView.text, message.count > 0
            {
                sendMessage(inputMessage: message)
            }
        }
                
        self.sendButton.isSelected = false
        self.sendButton.backgroundColor = UIColor.lightGray
        self.sendButton.isUserInteractionEnabled = false
        viewAttachmentInfo.isHidden = true
        view.layoutIfNeeded()
    }
    
    @IBAction func addAttachment(_ sender:UIButton)
    {
        chooseImageMethod()
    }
    
    @IBAction func clearAttachmentPressed(_ sender: Any)
    {
        inputTextField.isEnabled = true
        self.inputTextView.isEditable = true
        sendButton.isSelected = false
        sendButton.backgroundColor = UIColor.lightGray
        sendButton.isUserInteractionEnabled = false
        viewAttachmentInfo.isHidden = true
        view.layoutIfNeeded()
        
        attachmentData?.removeAll()
    }
    
    //MARK: - Helpers

    func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func getConverstaion()
    {
        self.channel = ChannelManager.sharedManager.currentChannel
        self.channel.delegate = self
        if ChannelManager.sharedManager.currentChannel.synchronizationStatus == .all
        {
            self.loadMessages()
            DispatchQueue.main.async
            {
                self.tableView?.reloadData()
                self.setViewOnHold(onHold: false)
            }
        }
        else
        {
            DispatchQueue.main.async
            {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
    }
    
    // Disable user input and show activity indicator
    func setViewOnHold(onHold: Bool)
    {
        self.chatInputView.isHidden = onHold;
        UIApplication.shared.isNetworkActivityIndicatorVisible = onHold;
    }
    
    func handleMessagingManagerConnectionError()
    {
        MessagingManager.sharedManager().connectClientWithCompletion
        { (success, error) in
            
            if success
            {
                MessagingManager.sharedManager().registerChatClientWith(deviceToken: (UIApplication.shared.delegate as! AppDelegate).updatedPushToken ?? Data.init())
                { (success, errorMessage) in

                    if success
                    {
                        self.loadChannelChatUponPush()
                    }
                    else
                    {
                    }
                }
            }
        }
    }
    
    func joinChannel()
    {
        setViewOnHold(onHold: true)
        
        if channel.status != .joined
        {
            channel.join
            { result in
                print("Channel Joined")
            }
            return
        }
        
        loadMessages()
        setViewOnHold(onHold: false)
    }
    
    //MARK: - Keyboard Observers
    
    @objc func keyboardDidAppear(notification: NSNotification)
    {
        let keyboardSize:CGSize = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        let height = min(keyboardSize.height, keyboardSize.width)
        UIView.animate(withDuration: 0.3)
        {
            DispatchQueue.main.async
            {
                var value = 0
                if let window = UIApplication.shared.windows.first
                {
                    value = Int(window.safeAreaInsets.bottom)
                }
                self.bottomMarginConstraint.constant = height - CGFloat(value)
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification)
    {
        print("Keyboard hidden")
        UIView.animate(withDuration: 0.3)
        {
            DispatchQueue.main.async
            {
                self.bottomMarginConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func closeKeyboard()
    {
        inputTextView.endEditing(true)
    }
    
    //MARK: - TextField Handling
    
    @objc func textFieldDidChange(_ textField: UITextField)
    {
        let haveText = textField.text?.count ?? 0 > 0
        self.sendButton.isSelected = haveText
        self.sendButton.backgroundColor = haveText ? UIColor.systemGreen : UIColor.lightGray
        self.sendButton.isUserInteractionEnabled = haveText
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        self.view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
         self.channel?.typing()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        self.channel?.typing()
    }

}

// MARK: - Chat Service

extension ChatViewController
{
    func sendMessage(inputMessage: String)
    {
        let messageOptions = TCHMessageOptions().withBody(inputMessage)
        channel.messages?.sendMessage(with: messageOptions, completion:
        { (result, message) in
            
            self.inputTextView.text = ""
        })
    }
    
    func addMessages(newMessages:Set<TCHMessage>)
    {
        messages =  messages.union(newMessages)
        sortMessages()
        DispatchQueue.main.async
        {
            self.tableView!.reloadData()
            if self.messages.count > 0
            {
                self.scrollToBottom()
            }
        }
    }
    
    func sortMessages()
    {
        sortedMessages = messages.sorted
        { (a, b) -> Bool in
            (a.dateCreated ?? "") < (b.dateCreated ?? "")
        }
    }
    
    func loadMessages()
    {
        messages.removeAll()
        if channel.synchronizationStatus == .all
        {
            channel.messages?.getLastWithCount(100)
            { (result, items) in
                self.addMessages(newMessages: Set(items!))
                
                DispatchQueue.main.async
                {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
        }
        else {
            DispatchQueue.main.async
            {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }
    
    func scrollToBottom()
    {
        if messages.count > 0
        {
            let indexPath = IndexPath(row: messages.count > 0 ? messages.count-1 : 0, section: 0)
            tableView!.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func leaveChannel()
    {
        channel.leave
        { result in
            if (result.isSuccessful())
            {
                
            }
        }
    }
}

// MARK: - UITableView

extension ChatViewController: UITableViewDelegate, UITableViewDataSource
{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let message = sortedMessages[indexPath.row]

        let date = NSDate.dateWithISO8601String(dateString: message.dateCreated ?? "")
        let timestamp = DateTodayFormatter().stringFromDate(date: date)
        
        if message.author == StateManager.shared.loginViewModel.userProfile?.providerCode
        {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: "ToChatTableViewCell") as? ToChatTableViewCell
            {
                if message.body?.contains("https://provider.drcurves.com") ?? false
                {
                    cell.messageLabel.text = "View Attachment"
                    cell.mediaImageView.isHidden = false
                    cell.messageLabel.isHidden = true
                    
                    if message.body?.contains(".doc") ?? false || message.body?.contains(".docx") ?? false
                    {
                        cell.mediaImageView.image =  #imageLiteral(resourceName: "word")
                    }
                    else if message.body?.contains(".pdf") ?? false
                    {
                        cell.mediaImageView.image =  #imageLiteral(resourceName: "pdf")
                    }
                    else
                    {
                        cell.mediaImageView.image =  #imageLiteral(resourceName: "picture")
                    }
                }
                else
                {
                    cell.messageLabel.text = message.body ?? ""
                    cell.messageLabel.isHidden = false
                    cell.mediaImageView.isHidden = true
                }
                cell.timeLabel.text = timestamp

                return cell
            }
        }
        else
        {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: "FromChatTableViewCell") as? FromChatTableViewCell
            {
                if message.body?.contains("https://provider.drcurves.com") ?? false
                {
                    cell.messageLabel.text = "View Attachment"
                    cell.mediaImageView.isHidden = false
                    cell.messageLabel.isHidden = true
                    
                    if message.body?.contains(".doc") ?? false || message.body?.contains(".docx") ?? false
                    {
                        cell.mediaImageView.image =  #imageLiteral(resourceName: "word")
                    }
                    else if message.body?.contains(".pdf") ?? false
                    {
                        cell.mediaImageView.image =  #imageLiteral(resourceName: "pdf")
                    }
                    else
                    {
                        cell.mediaImageView.image =  #imageLiteral(resourceName: "picture")
                    }
                }
                else
                {
                    cell.messageLabel.text = message.body ?? ""
                    cell.messageLabel.isHidden = false
                    cell.mediaImageView.isHidden = true
                }
                cell.timeLabel.text = timestamp

                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if sortedMessages[indexPath.row].body?.contains("https://provider.drcurves.com") ?? false
        {
            return 171 + 50 + 21
        }
        else
        {
            let string = sortedMessages[indexPath.row].body ?? ""
            let height = string.height(withConstrainedWidth: self.tableView.bounds.width - 100 - 10 - 36, font: UIFont.systemFont(ofSize: 15))
            return height + 50 + 21
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let message = sortedMessages[indexPath.row]
        
        if message.body?.contains("https://provider.drcurves.com") ?? false
        {
            let controller = self.storyboard?.instantiateViewController(identifier: "AttachmentViewController") as? AttachmentViewController
            controller?.webViewURL = message.body ?? ""
            self.navigationController?.pushViewController(controller!, animated: true)
        }
    }
    
}

// MARK: - TCHChannelDelegate

extension ChatViewController : TCHChannelDelegate
{
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, messageAdded message: TCHMessage)
    {
        if !messages.contains(message)
        {
            addMessages(newMessages: [message])
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberJoined member: TCHMember)
    {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, memberLeft member: TCHMember)
    {
        
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel)
    {
        DispatchQueue.main.async
        {
            if channel == self.channel
            {
                
            }
        }
    }
    
    func chatClient(_ client: TwilioChatClient,
                    channel: TCHChannel,
                    synchronizationStatusUpdated status: TCHChannelSynchronizationStatus)
    {
        if status == .all
        {
            loadMessages()
            DispatchQueue.main.async
            {
                self.tableView?.reloadData()
                self.setViewOnHold(onHold: false)
            }
        }
    }
    
    func chatClient(_ client: TwilioChatClient, typingStartedOn channel: TCHChannel, member: TCHMember)
    {
        self.topLabel.text = "\(toName) is typing...."
    }
    
    func chatClient(_ client: TwilioChatClient, typingEndedOn channel: TCHChannel, member: TCHMember)
    {
        self.topLabel.text = toName
    }
    
}




// MARK: - UIImagePicker Delegate / UINavigation Delegate

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    
    func sendAttachment()
    {
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.mode = MBProgressHUDMode.annularDeterminate
        progressHud.label.text = "Attachment Uploading..."
        // The data for the image you would like to send
        let data = attachmentData
        
        ChatViewModel.shared.uploadChatAttachment(attachment: data!, contentType: attachmentType, filename: attachmentName, progressHud: progressHud)
        { (attachmentURL) in
            
            self.inputTextView.isEditable = true
            
            self.attachmentData.removeAll()
            
            if attachmentURL != ""
            {
                self.sendMessage(inputMessage: attachmentURL ?? "")
            }
            
            progressHud.hide(animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        var image : UIImage?
        
        if let pickedImage = info[.editedImage] as? UIImage
        {
            image   =   pickedImage
        }
        else if let pickedImage = info[.originalImage] as? UIImage
        {
            image   =   pickedImage
        }
        
        DispatchQueue.main.async
        {
            if image != nil
            {
                if let imageData = image!.pngData()
                {
                    self.attachmentName = "image.jpg"
                    self.attachmentType = "image/jpg"
                    
                    self.attachmentData = imageData
                    
                    self.labelAttachmentName.text = "Image Attached"
                    self.attachmentTypeImage.image = image
                    self.viewAttachmentInfo.isHidden = false
                    self.inputTextField.isEnabled = false
                    self.inputTextView.isEditable = false
                    self.sendButton.isSelected = true
                    self.sendButton.backgroundColor = UIColor.systemGreen
                    self.sendButton.isUserInteractionEnabled = true
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func openCamera()
    {
        if (UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openGallery ()
    {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func openFileManager()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF),"com.microsoft.word.doc","org.openxmlformats.wordprocessingml.document",String(kUTTypeJPEG),String(kUTTypePNG),String(kUTTypeImage),String(kUTTypeJPEG2000)], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func chooseImageMethod()
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        if let popoverPresentationController = alert.popoverPresentationController
        {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect =  CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY / 2.5, width: 0, height: 0)
        }
        
        let GalleryAction: UIAlertAction = UIAlertAction(title: "Choose from Library", style: .default)
        { action -> Void in
            self.openGallery()
        }
        
        let CameraAction: UIAlertAction = UIAlertAction(title: "Take photo", style: .default )
        { action -> Void in
            self.openCamera()
        }
        
        let FileAction: UIAlertAction = UIAlertAction(title: "Choose File", style: .default )
        { action -> Void in
            self.openFileManager()
        }
        
        let CancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel )
        { action -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(GalleryAction)
        alert.addAction(CameraAction)
        alert.addAction(FileAction)
        alert.addAction(CancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPicker Delegate

extension ChatViewController: UIDocumentMenuDelegate,UIDocumentPickerDelegate
{
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
    {
        guard let myURL = urls.first else
        {
            return
        }
        
        do
        {
            let data = try Data.init(contentsOf: myURL)
            
            let fileExt: String = myURL.pathExtension
            
            if fileExt.contains("pdf"){
                self.attachmentName = "file.pdf"
                self.attachmentType = "application/pdf"
            }else if fileExt.contains("doc"){
                self.attachmentName = "file.doc"
                self.attachmentType = "application/msword"
            }else if fileExt.contains("docx"){
                self.attachmentName = "file.docx"
                self.attachmentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            }else if fileExt.contains("png"){
                self.attachmentName = "image.png"
                self.attachmentType = "image/png"
            }else if fileExt.contains("jpeg"){
                self.attachmentName = "image.jpeg"
                self.attachmentType = "image/jpeg"
            }else if fileExt.contains("jpg"){
                self.attachmentName = "image.jpg"
                self.attachmentType = "image/jpg"
            }
            
            self.attachmentData = data
            
            if fileExt.contains("doc") || fileExt.contains("docx")
            {
                self.attachmentTypeImage.image =  #imageLiteral(resourceName: "word")
            }
            else if fileExt.contains("pdf")
            {
                self.attachmentTypeImage.image =  #imageLiteral(resourceName: "pdf")
            }
            else
            {
                self.attachmentTypeImage.image =  #imageLiteral(resourceName: "picture")
            }
            
            self.labelAttachmentName.text = "File Attached"
            self.viewAttachmentInfo.isHidden = false
            self.inputTextField.isEnabled = false
            self.inputTextView.isEditable = false
            self.sendButton.isSelected = true
            self.sendButton.backgroundColor = UIColor.systemGreen
            self.sendButton.isUserInteractionEnabled = true
            self.view.layoutIfNeeded()
        }
        catch
        {
            print("Unable to load data: \(error)")
        }
    }
    
    public func documentMenu(_ documentMenu:UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController)
    {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
    {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}
