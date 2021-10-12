//
//  DashbaordViewController.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import UIKit
import FTPopOverMenu_Swift
import TwilioVoice
import NotificationBannerSwift
import MBProgressHUD
import SafariServices
import TwilioChatClient

class DashbaordViewController: UIViewController, UIPopoverPresentationControllerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var containerView:UIView!
    @IBOutlet weak var topNameLabel:UILabel!
    @IBOutlet weak var topPhoneNumber:UILabel!
    @IBOutlet weak var openTaskButton:UIButton!
    @IBOutlet weak var addMembersButton:UIButton!
    @IBOutlet weak var patientBannerView:UIView!
    @IBOutlet weak var patientNameLabel:UILabel!
    @IBOutlet weak var patientTitleLabel:UILabel!
    @IBOutlet weak var patientGroupNameLabel:UILabel!
    @IBOutlet weak var patientHoldUnholdButton:UIButton!
    @IBOutlet weak var segmentControl:UISegmentedControl!
    @IBOutlet weak var patientActivity:UIActivityIndicatorView!
    @IBOutlet weak var callTopInfoViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet weak var searchBar:UISearchBar! {
        didSet {
            self.searchBar.delegate = self
        }
    }
    
    var currentSelectedIndex:Int = 0
    var observer = StateManager.shared
    var patientDetails:PatientDetails?
    var activeTaskList:[ActiveTask] = []
    var currentViewController:UIViewController?
    var callConManager = CallConnectivityManager.shared
    
    private lazy var firstViewController: CallHistoryViewController = {

        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "CallHistoryViewController") as! CallHistoryViewController
        viewController.delegate = self
        self.add(asChildViewController: viewController)
        return viewController
        
    }()

    private lazy var secondViewController: DialerViewController = {

        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "DialerViewController") as! DialerViewController
        self.add(asChildViewController: viewController)
        viewController.delegate = self
        return viewController
        
    }()
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (UIApplication.shared.delegate as? AppDelegate)?.handleSavedNotification()
        
        self.setupView()
        
        let name = observer.loginViewModel.userProfile?.fullName ?? "World"
        let phone = observer.loginViewModel.defaultPhoneNumber
        self.topNameLabel.text = name
        self.topPhoneNumber.text = phone
        
        self.patientBannerView.isHidden = true
        self.patientActivity.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.callDidEnd), name: NSNotification.Name("CALLDIDEND"), object: nil)
        self.patientHoldUnholdButton.isHidden = true
        
    }
    
    //MARK: - IBActions
    @IBAction func changeNumber(_ sender:UIButton) {
        
        let phones = self.observer.loginViewModel.userFromNumbers
        if phones.count > 0 {
            self.showUserPhones(phones, sender: sender)
        }
        else {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            let providerCode = self.observer.loginViewModel.userProfile?.providerCode ?? ""
            self.observer.loginViewModel.getUserFromNumbers(providerCode) { (activeNumbers, error) in
                MBProgressHUD.hide(for: self.view, animated: false)
                
                guard let tasks = activeNumbers else {
                    NotificationBanner(title: nil, subtitle: "Unable to get User's numbers, Please try again", style: .danger).show()
                    return
                }
                
                if tasks.count > 0 {
                    self.showUserPhones(tasks, sender: sender)
                }
            }
        }
    }
    
    func showUserPhones(_ tasks:[ActiveTask], sender:UIButton) {
        let configuration = FTConfiguration()
        configuration.menuRowHeight = 60
        configuration.menuWidth = 300
        configuration.backgoundTintColor = UIColor.darkGray
        
        self.observer.loginViewModel.userFromNumbers = tasks
        
        let phoneNumbers = tasks.map({ (task) -> String in
            return String("\(task.taskGroupName ?? "")\n\(task.cellNumber ?? "")")
        })
        
        FTPopOverMenu.showForSender(sender: sender, with: phoneNumbers, menuImageArray: nil, config:configuration, done: { (selectedIndex) -> () in
                if let selectedName = phoneNumbers[selectedIndex].components(separatedBy: "\n").first, let selectedPhone = phoneNumbers[selectedIndex].components(separatedBy: "\n").last {
                    self.observer.loginViewModel.defaultPhoneNumber = selectedPhone
                    self.topPhoneNumber.text = selectedPhone
                    self.topNameLabel.text = selectedName
                }
        }) { }
    }
    
    @objc func callDidEnd() {
        self.patientHoldUnholdButton.setImage(UIImage(systemName: "iphone"), for: .normal)
        self.patientHoldUnholdButton.tag = 0
        self.patientHoldUnholdButton.isHidden = true
    }
   
    @IBAction func openTaskAction(_ sender:UIButton) {
        if let validDetails = self.patientDetails, validDetails.data != nil {
            let patientID = (validDetails.data?.first?.patientID ?? "").replacingOccurrences(of: " ", with: "%20")
            let taskID = (validDetails.data?.first?.taskID ?? "").replacingOccurrences(of: " ", with: "%20")
            let taskType = (validDetails.direction ?? "").appending("%20Call")
            
            var returnURL = "/Patient/Index?pid=\(patientID)&tid=\(taskID)&tasktype=\(taskType)"
            
            returnURL = returnURL.replacingOccurrences(of: "/", with: "%2F")
            returnURL = returnURL.replacingOccurrences(of: "?", with: "%3F")
            returnURL = returnURL.replacingOccurrences(of: "=", with: "%3D")
            returnURL = returnURL.replacingOccurrences(of: "&", with: "%26")
            let url = "https://provider.drcurves.com/Account/Login?returnUrl=\(returnURL)"
            
            if let validURL = URL(string: url) {
                let vc = SFSafariViewController(url: validURL)
                self.present(vc, animated: true, completion: nil)
            }
            else {
                NotificationBanner(title: "Unable to open URL", subtitle: "\(url)", style: .warning).show()
            }
        }
        else {
            NotificationBanner(title: "Response data is invalid or empty", style: .warning).show()
        }
    }
    
    @IBAction func showMembersList(_ sender:UIButton) {
        if self.callConManager.activeCall != nil {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.observer.loginViewModel.getListOfActiveTasks { (activeTasks, error) in
                MBProgressHUD.hide(for: self.view, animated: false)
                
                guard let tasks = activeTasks else {
                    NotificationBanner(title: nil, subtitle: "Unable to get Task list, Please try again", style: .danger).show()
                    return
                }
                
                if tasks.count > 0 {
                    if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ActiveTasksViewController") as? ActiveTasksViewController {
                        controller.activeTaskList = tasks
                        controller.deletgate = self
                        self.present(controller, animated: true, completion: nil)
                    }
                    
                }
                else {
                    NotificationBanner(title: nil, subtitle: "No active tasks found", style: .warning).show()
                }
            }
        }
        else {
            NotificationBanner(title: nil, subtitle: "You can only add people during Active call.", style: .warning).show()
        }
    }
    
    @IBAction func patientHoldUnholdButtonPressed(_ sender:UIButton) {
        if let validCall = self.callConManager.activeCall {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            let value = sender.tag == 1 ? "hold" : "resume"
            
            self.observer.loginViewModel.changePatientCallStatus(with: value, callSID: validCall.sid, direction: self.callConManager.currentCallDirection ?? "") { (respone, error) in
                MBProgressHUD.hide(for: self.view, animated: false)
                
                if let validResponse = respone, let res = validResponse.res {
                    if res == 1 {
                        NotificationBanner(title: nil, subtitle: "Successfully \(value)", style: .success).show()
                        
                        if value == "hold" {
                            self.patientHoldUnholdButton.setImage(UIImage(systemName: "iphone.slash"), for: .normal)
                            self.patientHoldUnholdButton.tag = 2
                        }
                        else {
                            self.patientHoldUnholdButton.setImage(UIImage(systemName: "iphone"), for: .normal)
                            self.patientHoldUnholdButton.tag = 1
                        }
                    }
                    else if let message = validResponse.data {
                        NotificationBanner(title: nil, subtitle: message, style: .danger).show()
                    }
                    else {
                        NotificationBanner(title: nil, subtitle: "Reponse object is not valid or empty", style: .danger).show()
                    }
                }
                else {
                    NotificationBanner(title: nil, subtitle: "\(error ?? "Something went wrong")", style: .danger).show()
                }
            }
        }
        else {
            NotificationBanner(title: nil, subtitle: "You can only add people during Active call.", style: .warning).show()
        }
    }
    
    
    //MARK: - SearchBar Delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text, text.trimmingCharacters(in: CharacterSet.whitespaces).count > 0 {
            searchBar.resignFirstResponder()
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.observer.loginViewModel.searchPatient(text) { (searchResponse, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                if let validError = error {
                    NotificationBanner(title: nil, subtitle: "Error Occured \(validError.description)", style: .danger).show()
                }
                else if let validResponse = searchResponse {
                    if let patients = validResponse.data, patients.count > 0 {
                        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "PatientsViewController") as? PatientsViewController {
                            controller.currentSearchedPatients = patients
                            controller.deletgate = self
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                    else {
                        NotificationBanner(title: nil, subtitle: "No matched result found.", style: .warning).show()
                    }
                }
                else {
                    NotificationBanner(title: nil, subtitle: "Error Occured", style: .danger).show()
                }
            }
        }
        else {
            searchBar.resignFirstResponder()
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender:UISegmentedControl) {
        self.view.endEditing(true)
        if self.callConManager.activeCall == nil {
            self.secondViewController.callNumberLabel.text = ""
        }
        updateView()
    }
    
    @IBAction func showSideMenu(_ sender:UIButton) {
        let configuration = FTConfiguration()
            configuration.menuRowHeight = 60
            configuration.menuWidth = 200
        configuration.backgoundTintColor = UIColor.darkGray
        
        let statusTitle = self.observer.currentStatus.rawValue
        FTPopOverMenu.showForSender(sender: sender, with: [statusTitle, "Dashboard", "Dialer", "Call History", "SMS", "Chat", "Settings", "Logout"], menuImageArray: [statusTitle, "home","dial-pad", "callhistory", "sms", "chat", "settings","logout"], config:configuration, done: { (selectedIndex) -> () in
                                        
                if selectedIndex == 0 {
                    self.showStatusActionSheet()
                }
                else if selectedIndex == 1 {
                    self.openHomePage()
                }
                else if selectedIndex == 2 {
                    self.secondViewController.callNumberLabel.text = ""
                    self.segmentControl.selectedSegmentIndex = 1
                    self.updateView()
                }
                else if selectedIndex == 3 {
                    self.segmentControl.selectedSegmentIndex = 0
                    self.updateView()
                    
                }
                else if selectedIndex == 4 {
                    self.showSMSHistoryView()
                }
                else if selectedIndex == 5 {
                    self.showContactListView()
                }
                else if selectedIndex == 6 {
                    self.gotoSettings()
                }
                else if selectedIndex == 7 {
                    self.showLogoutAlert()
                }
        }) {
            
        }
    }
    
    //MARK: - Helpers
    
    func getDirectionAndCustomer() -> (direction:String, customer:String) {
        let direction = self.callConManager.currentCallDirection ?? ""
        if direction.lowercased() == "outbound" {
            return (direction, self.secondViewController.callNumberLabel.text ?? "")
        }
        else {
            return (direction, self.callConManager.activeCall?.from ?? "")
        }
    }
    
    func openHomePage() {
        let url = "https://provider.drcurves.com/dashboard/index"
        if let validURL = URL(string: url) {
            let vc = SFSafariViewController(url: validURL)
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func gotoSettings() {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func showStatusActionSheet() {
        guard self.observer.inCall == false else {
            NotificationBanner(title: nil, subtitle: "You can't change status during call.", style: .warning).show()
            return
        }
        let alertController = UIAlertController(title: "Change Status", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Idle", style: .default, handler: { (action) in
            self.updateStatus("Idle")
        }))
        alertController.addAction(UIAlertAction(title: "Offline", style: .default, handler: { (action) in
            self.updateStatus("Offline")
        }))
        alertController.addAction(UIAlertAction(title: "Busy", style: .default, handler: { (action) in
            self.updateStatus("Busy")
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateStatus(_ status:String) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let workerSID = self.observer.loginViewModel.userProfile?.workerSid ?? ""
        self.observer.loginViewModel.setNewWorkerStatus(workerSID, status: status) { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if let responseStatus = response?.activityName {
                if responseStatus.lowercased().contains("offline") {
                    self.observer.currentStatus = .offline
                }
                else if responseStatus.lowercased().contains("idle") {
                    self.observer.currentStatus = .online
                }
                else if responseStatus.lowercased().contains("busy") {
                    self.observer.currentStatus = .busy
                }
            }
            else {
                NotificationBanner(title: nil, subtitle: "Failed to set worker status.", style: .danger).show()
            }
        }
    }
    
    func showLogoutAlert() {
        let alertController = UIAlertController(title: "Logout", message: "Are you sure to logout?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
            if let validDeviceData = UserDefaults.standard.data(forKey: kCachedDeviceToken), let validAccessToken = self.observer.loginViewModel.userProfile?.twillioToken
            {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                
                let myGroup = DispatchGroup()

                myGroup.enter() //for `checkSpeed`
                myGroup.enter() //for `doAnotherAsync`
                
                TwilioVoice.unregister(accessToken: validAccessToken, deviceToken: validDeviceData)
                { (error) in
                    NSLog("LOGOUT: Successfully unregister for VoIP push notifications.")
                    myGroup.leave()
                }
                
                MessagingManager.sharedManager().logout
                { (success, errorMessage) in
                    NSLog("LOGOUT: Successfully unregister for Chat push notifications.")
                    myGroup.leave()
                }
                
                myGroup.notify(queue: DispatchQueue.main)
                {
                    MBProgressHUD.hide(for: self.view, animated: true)

                    UserDefaults.standard.removeObject(forKey: AppConstants.USER_ACCESS_TOKEN)
                    UserDefaults.standard.removeObject(forKey: AppConstants.USER_PROFILE_MODEL)
                    UserDefaults.standard.removeObject(forKey: "currentStatus")
                    UserDefaults.standard.synchronize()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showSMSHistoryView() {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "SMSHistoryViewController") as? SMSHistoryViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func showContactListView() {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ContactListViewController") as? ContactListViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension DashbaordViewController: ActiveTasksSelectionProtocol {
    func taskDidSelected(_ tasks: ActiveTask) {
        self.addSelectedMemberToCall(tasks)
    }
    
    func addSelectedMemberToCall(_ memner:ActiveTask) {
        
        guard let activeCall = self.callConManager.activeCall else {
            return
        }
        
        let otherParam = self.getDirectionAndCustomer()
        
        let progress = MBProgressHUD.showAdded(to: self.view, animated: true)
        progress.label.text = "Adding \(memner.taskGroupName ?? "Task") to Call..."
        self.observer.loginViewModel.addToCall(memner, callSID: activeCall.sid, toNumber: otherParam.customer, callDirection: otherParam.direction) { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if let validResponse = response, let res = validResponse.res {
                if res == 1 {
                    NotificationBanner(title: nil, subtitle: "Successfully added", style: .success).show()
                    self.patientHoldUnholdButton.isHidden = false
                    self.patientHoldUnholdButton.setImage(UIImage(systemName: "iphone.slash"), for: .normal)
                    self.patientHoldUnholdButton.tag = 2
                }
                else if let message = validResponse.data {
                    NotificationBanner(title: nil, subtitle: message, style: .danger).show()
                }
                else {
                    NotificationBanner(title: nil, subtitle: "Reponse object is not valid or empty", style: .danger).show()
                }
            }
            else {
                NotificationBanner(title: nil, subtitle: "\(error ?? "Something went wrong")", style: .danger).show()
            }
        }
        
    }
    
}

extension DashbaordViewController: IncomingCallProgressProtocol {
    
    func incomingCallStatusChanged(status: Bool, direction:String) {
        
        if status == true {
            UIView.animate(withDuration: 0.3) {
                self.callTopInfoViewHeightConstraint.constant = 60
                self.view.setNeedsLayout()
                self.patientBannerView.isHidden = false
            }
            self.patientActivity.startAnimating()
            self.patientActivity.isHidden = false
            self.openTaskButton.isHidden = true
            
            let providerCode = self.observer.loginViewModel.userProfile?.providerCode ?? ""
            let incomingCallSID = self.callConManager.activeCall?.sid ?? ""
            self.observer.loginViewModel.copyCallTaskToTasks(with: providerCode, callSID: incomingCallSID, direction: direction) { (patientDetails, error) in
                
                if let validPatientDetails = patientDetails {
                    DispatchQueue.main.async {
                        self.patientActivity.stopAnimating()
                        self.patientActivity.isHidden = true
                        self.openTaskButton.isHidden = false
                        
                        var fullName = ""
                        if let firstName = validPatientDetails.data?.first?.firstName {
                            fullName.append("\(firstName) ")
                        }
                        if let lastName = validPatientDetails.data?.first?.lastName {
                            fullName.append("\(lastName) ")
                        }
                        if let taskID = validPatientDetails.data?.first?.taskID {
                            fullName.append("(\(taskID))")
                        }
                        
                        if let patientID = validPatientDetails.data?.first?.patientID, patientID.count > 0, patientID != "0" {
                            self.patientNameLabel.text = fullName
                            self.patientNameLabel.isHidden = false
                        }
                        else {
                            self.patientNameLabel.isHidden = true
                        }
                        
                        self.patientTitleLabel.text = "\(validPatientDetails.data?.first?.title ?? "Patient Title")"
                        self.patientGroupNameLabel.text = "\(validPatientDetails.data?.first?.groupName ?? "Group Name")"
                        
                        self.patientDetails = validPatientDetails
                        self.patientDetails?.direction = direction
                        
                        print("^^^\n fullName:\(fullName)\n self.patientTitleLabel.text:\(self.patientTitleLabel.text ?? "")\n self.patientGroupNameLabel.text: \(self.patientGroupNameLabel.text ?? "")\n \n^^^")
                    }
                }
                else {
                    NotificationBanner(title: nil, subtitle: "Unable to get Patient details", style: .warning).show()
                }
            }
        }
        else {
            self.patientActivity.isHidden = true
        }
    }
    
}


extension DashbaordViewController: CallHistoryNumberSelectionProtocol {
    func didSelectNumber(_ number: String?) {
        if let validNumber = number {
            self.segmentControl.selectedSegmentIndex = 1
            self.secondViewController.callNumberLabel.text = validNumber
            self.updateView()
        }
    }
}

extension DashbaordViewController: PatientSelectionProtocol, NewMessageConversationDelegate {
    func patientDidSelected(_ patient: Patient, isCall:Bool) {
        self.searchBar.text = ""
        let countryCode = patient.country ?? ""
        let number = "\(countryCode)\(patient.cellNumber ?? "")"
        
        if isCall {
            self.segmentControl.selectedSegmentIndex = 1
            self.secondViewController.callNumberLabel.text = number
            self.updateView()
        }
        else {
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "NewMessageViewController") as? NewMessageViewController {
                controller.inputString = number
                controller.delegate = self
                self.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func newMessageCreated(_ selectedChat: HistoryResponseElement) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ConvesationViewController") as? ConvesationViewController {
            controller.selectedChat = selectedChat
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension DashbaordViewController {

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    private func add(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }

    private func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    private func updateView() {
        if segmentControl.selectedSegmentIndex == 0 {
            remove(asChildViewController: secondViewController)
            add(asChildViewController: firstViewController)
        } else {
            remove(asChildViewController: firstViewController)
            add(asChildViewController: secondViewController)
        }
    }
    
    static func viewController() -> DashbaordViewController {
        return UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DashbaordViewController") as! DashbaordViewController
    }

    func setupView() {
        updateView()
    }
}
