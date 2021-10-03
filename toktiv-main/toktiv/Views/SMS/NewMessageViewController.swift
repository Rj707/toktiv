//
//  NewMessageViewController.swift
//  toktiv
//
//  Created by Developer on 23/11/2020.
//

import UIKit
import MBProgressHUD
import GrowingTextView

protocol NewMessageConversationDelegate {
    func newMessageCreated(_ selectedChat:HistoryResponseElement)
}

class NewMessageViewController: UIViewController, GrowingTextViewDelegate {
    
    @IBOutlet weak var sendButton:UIButton!
    @IBOutlet weak var numberField:UITextField!
    @IBOutlet weak var inputTextView:GrowingTextView!
    @IBOutlet weak var bottomMarginConstraint:NSLayoutConstraint!
    
    var inputString:String = ""
    var observer = StateManager.shared
    var delegate:NewMessageConversationDelegate?

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addObservers()
        self.addAccessoryView()
        
        numberField.text = inputString
        
        configureInputTextView()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
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
    
    
    //MARK: - IBActions
    
    @IBAction func sendMessage(_ sender:UIButton) {
        if let message = self.inputTextView.text {
            let accessToken = self.observer.loginViewModel.userAccessToken
            let from = self.observer.loginViewModel.defaultPhoneNumber
            let to = self.numberField.text ?? ""
            self.view.endEditing(true)
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.observer.userHistoryViewModel.sendMessage(accessToken, message: message, from: from, to: to) { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                
                if let res = response?.res, res == 1 {
                    self.inputTextView.text = ""
                    self.dismiss(animated: true) {
                        let chatObject = HistoryResponseElement(with: to, from: from, direction: "Outbound")
                        self.delegate?.newMessageCreated(chatObject)
                    }
                }
                else {
                    self.showMessage(response?.data ?? response?.message ?? "Unable to send message")
                }
            }
            
        }
    }
    
    @IBAction func popThisController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Helpers
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    public func addAccessoryView() {
        let doneButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(keyboardDone))
        let flexSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let toolbar = UIToolbar()
        toolbar.barStyle = UIBarStyle.default
        toolbar.isTranslucent = true
        toolbar.tintColor = UIColor.blue
        toolbar.sizeToFit()
        toolbar.setItems([flexSpace, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        numberField.inputAccessoryView = toolbar
    }
    
    //MARK: - Keyboard Handling
    
    @objc func keyboardDone() {
        self.view.endEditing(true)
    }
    
    
    @objc func keyboardDidAppear(notification: NSNotification) {
        guard inputTextView.isFirstResponder == true else { return }
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
