//
//  DialerViewController.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import UIKit
import PushKit
import CallKit
import TwilioVoice
import AVFoundation
import NotificationBannerSwift


protocol IncomingCallProgressProtocol {
    func incomingCallStatusChanged(status:Bool, direction:String)
}

class DialerViewController: UIViewController {
    
    
    @IBOutlet weak var callNumberLabel:UILabel!
    @IBOutlet weak var placeCallButton: UIButton!
    
    @IBOutlet weak var speakerButton:UIButton!
    @IBOutlet weak var micButton:UIButton!
    
    @IBOutlet weak var keyboardButton:UIButton!
    @IBOutlet weak var numberStack:UIStackView!
    @IBOutlet weak var alphabetStack:UIStackView!
    
    @IBOutlet weak var durationLabel:UILabel!
    
    var delegate:IncomingCallProgressProtocol?
    var callConManager = CallConnectivityManager.shared
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.keyboardButton.isSelected = true
        
        self.callConManager.connectivityDelegate = self
    }
    
    
    //MARK: - IBActions
    
    @IBAction func numberButtonPressed(_ sender:UIButton) {
        
        guard self.callConManager.activeCall == nil else {
            return
        }
        let numberToBeAdded = sender.tag
        AudioServicesPlaySystemSound(1105)
        callNumberLabel.text?.append("\(numberToBeAdded)")
    }
    
    @IBAction func toggelKeyboard(_ sender:UIButton) {
        if sender.isSelected {
            self.numberStack.isHidden = true
            self.alphabetStack.isHidden = false
        }
        else {
            self.numberStack.isHidden = false
            self.alphabetStack.isHidden = true
        }
        
        sender.isSelected = !sender.isSelected
    }
    
    
    @IBAction func holdUnholdButton(_ sender:UIButton) {
        guard let validCall = self.callConManager.activeCall else {
            return
        }
        
        let newValue = !sender.isSelected
        
        validCall.isOnHold = newValue
        sender.isSelected = newValue
    }
    
    
    @IBAction func plusButtonPressed(_ sender:UIButton) {
        
        guard self.callConManager.activeCall == nil else {
            return
        }
        guard let validText = self.callNumberLabel.text else {
            return
        }
        
        AudioServicesPlaySystemSound(1105)
        
        if sender.currentTitle == "+" && !(validText.contains("+")) && validText == "" {
            callNumberLabel.text?.append("+")
        }
        else if sender.currentTitle == "-" && !(validText.contains("-")) {
            callNumberLabel.text?.append("-")
        }
        else if sender.currentTitle == ":" && !(validText.contains(":")) {
            callNumberLabel.text?.append(":")
        }
    }
    
    @IBAction func alphabetPressed(_ sender:UIButton) {
        
        guard self.callConManager.activeCall == nil else {
            return
        }
        let numberToBeAdded = sender.currentTitle ?? ""
        callNumberLabel.text?.append("\(numberToBeAdded)")
    }
    
    @IBAction func removeNumber(_ sender:UIButton) {
        
        
        guard self.callConManager.activeCall == nil else {
            return
        }
        if callNumberLabel.text?.count ?? 0 > 0 {
            callNumberLabel.text?.removeLast()
        }
    }
    
    @IBAction func mainButtonPressed(_ sender: Any) {
        
        if let number = self.callNumberLabel.text, number.count == 0 && self.callConManager.activeCall == nil {
            
            DispatchQueue.main.async {
                let notificationBanner = NotificationBanner(title: nil, subtitle: "Please enter valid Number", style: .warning)
                notificationBanner.show()
            }
            return
        }
        
        
        guard self.callConManager.activeCall == nil else {
            self.callConManager.userInitiatedDisconnect = true
            self.callConManager.performEndCallAction(uuid: self.callConManager.activeCall!.uuid!)
            
            return
        }
        
        self.callConManager.callNumber = self.callNumberLabel.text ?? ""
        
        checkRecordPermission { [weak self] permissionGranted in
            let uuid = UUID()
            let handle = "TokTiv"
            
            guard !permissionGranted else {
                self?.callConManager.currentCallDirection = "Outbound"
                self?.callConManager.performStartCallAction(uuid: uuid, handle: handle)
                return
            }
            
            self?.showMicrophoneAccessRequest(uuid, handle)
        }
    }
    
    @IBAction func toggleSpeakerUsingButton(_ sender:UIButton) {
        toggleAudioRoute(toSpeaker: !sender.isSelected)
    }
    
    @IBAction func toggleMicUsingButton(_ sender:UIButton) {
        if sender.isSelected {
            self.setCallMuted(enabled: true)
        }
        else {
            self.setCallMuted(enabled: false)
        }
    }
    
    //MARK: - Permission Handling
    
    func showMicrophoneAccessRequest(_ uuid: UUID, _ handle: String) {
        let alertController = UIAlertController(title: "TokTiv",
                                                message: "Microphone permission not granted",
                                                preferredStyle: .alert)
        
        let continueWithoutMic = UIAlertAction(title: "Continue without microphone", style: .default) { [weak self] _ in
            self?.callConManager.performStartCallAction(uuid: uuid, handle: handle)
        }
        
        let goToSettings = UIAlertAction(title: "Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                      options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                      completionHandler: nil)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            
        }
        
        [continueWithoutMic, goToSettings, cancel].forEach { alertController.addAction($0) }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func checkRecordPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        
        switch permissionStatus {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in completion(granted) }
        default:
            completion(false)
        }
    }
    
    
    
    // MARK: - AVAudioSession
    
    func setCallMuted(enabled: Bool) {
        guard let activeCall = self.callConManager.activeCall else { return }
        
        activeCall.isMuted = enabled
        micButton.isSelected = !enabled
    }
    
    func toggleAudioRoute(toSpeaker: Bool) {
        
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.voiceChat)
        if toSpeaker {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            self.speakerButton.isSelected = true
        } else {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            self.speakerButton.isSelected = false
        }
        try? session.setActive(true)
    }
}

//MARK: -
extension DialerViewController: CallConnectivityDelegate {
    func updateDurationLabel(_ text: String, isHidden: Bool) {
        self.durationLabel.text = text
        self.durationLabel.isHidden = isHidden
    }
    
    func updatePlaceCallButton(_ tintColor: UIColor) {
        self.placeCallButton.tintColor = tintColor
    }
    
    func incomingCallStatusConnectivity(status: Bool, direction: String) {
        self.delegate?.incomingCallStatusChanged(status: status, direction: direction)
    }
    
    func muteCurrentCall(enabled: Bool) {
        self.setCallMuted(enabled: enabled)
    }
    
    
}
