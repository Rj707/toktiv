//
//  CallConnectivityManager.swift
//  toktiv
//
//  Created by Developer on 10/12/2020.
//
import Foundation
import PushKit
import CallKit
import TwilioVoice
import AVFoundation
import NotificationBannerSwift

let twimlParamTo = "phoneNumber"
let twimlParamFrom = "Twillio_PhoneNumber"
let twimlParamCallerAgent = "CallerAgent"
let kCachedDeviceToken = "CachedDeviceToken"

protocol CallConnectivityDelegate {
    func updateDurationLabel(_ text:String, isHidden:Bool)
    func updatePlaceCallButton(_ tintColor:UIColor)
    func incomingCallStatusConnectivity(status:Bool, direction:String)
    func muteCurrentCall(enabled:Bool)
    func toggleAudioRoute(toSpeaker:Bool)
}

class CallConnectivityManager: NSObject {
    
    static let shared = CallConnectivityManager()
    
    var callTimer:Timer?
    var callStartDate:Date?
    var callNumber:String = ""
    var currentCallDirection:String? = nil
    var observer = StateManager.shared
    var audioDevice = DefaultAudioDevice()
    var activeCalls: [String: Call]! = [:]
    var activeCallInvites: [String: CallInvite]! = [:]
    var connectivityDelegate:CallConnectivityDelegate?
    var callKitCompletionCallback: ((Bool) -> Void)? = nil
    
    var callKitProvider: CXProvider?
    let callKitCallController = CXCallController()
    var userInitiatedDisconnect: Bool = false
    
    var playCustomRingback = false
    var ringtonePlayer: AVAudioPlayer? = nil
    
    var currentStatus: AvailableStatus = .online
    var incomingPushCompletionCallback: (() -> Void)?
    
    var activeCall: Call? = nil {
        didSet {
            if activeCall == nil {
                self.currentCallDirection = nil
                self.connectivityDelegate?.updateDurationLabel("", isHidden: true)
                callTimer?.invalidate()
                callTimer = nil
                NotificationCenter.default.post(name: NSNotification.Name("CALLDIDEND"), object: nil)
            }
            else {
                callStartDate = Date()
                callTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
            }
        }
    }
  
    func fetchAccessToken() -> String? {
        return self.observer.loginViewModel.userProfile?.twillioToken
    }
    
    @objc func updateTime() {
        if let validCallDate = self.callStartDate {
            let nowDate = Date()
            let seconds = validCallDate.distance(to: nowDate)
            let completeDuration = self.secondsToHoursMinutesSeconds(seconds: Int(seconds))
            let h = String(format: "%02d", completeDuration.0)
            let m = String(format: "%02d", completeDuration.1)
            let s = String(format: "%02d", completeDuration.2)
            self.connectivityDelegate?.updateDurationLabel("\(h):\(m):\(s)", isHidden: false)

        }
        else {
            self.connectivityDelegate?.updateDurationLabel("", isHidden: true)
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
      return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    deinit {
        if let provider = callKitProvider {
            provider.invalidate()
        }
    }
    
    override init() {
        super.init()
        let configuration = CXProviderConfiguration(localizedName: "TokTiv")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        callKitProvider = CXProvider(configuration: configuration)
        if let provider = callKitProvider {
            provider.setDelegate(self, queue: nil)
        }
        
        TwilioVoice.audioDevice = audioDevice
    }

}

// MARK: - PushKitEventDelegate
extension CallConnectivityManager: PushKitEventDelegate {
    func credentialsUpdated(credentials: PKPushCredentials) {
        guard
            let accessToken = fetchAccessToken(),
            UserDefaults.standard.data(forKey: kCachedDeviceToken) != credentials.token
        else { return }

        let cachedDeviceToken = credentials.token
        
        TwilioVoice.register(accessToken: accessToken, deviceToken: cachedDeviceToken) { error in
            if let error = error {
                NSLog("An error occurred while registering: \(error.localizedDescription)")
            } else {
                NSLog("Successfully registered for VoIP push notifications.")
               
                UserDefaults.standard.set(cachedDeviceToken, forKey: kCachedDeviceToken)
            }
        }
    }
    
    func credentialsInvalidated() {
        guard let deviceToken = UserDefaults.standard.data(forKey: kCachedDeviceToken),
            let accessToken = fetchAccessToken() else { return }
        
        TwilioVoice.unregister(accessToken: accessToken, deviceToken: deviceToken) { error in
            if let error = error {
                NSLog("An error occurred while unregistering: \(error.localizedDescription)")
            } else {
                NSLog("Successfully unregistered from VoIP push notifications.")
            }
        }
        
        UserDefaults.standard.removeObject(forKey: kCachedDeviceToken)
    }
    
    func incomingPushReceived(payload: PKPushPayload) {
        TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }
    
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
        
        if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
            incomingPushCompletionCallback = completion
        }
    }

    func incomingPushHandled() {
        guard let completion = incomingPushCompletionCallback else { return }
        
        incomingPushCompletionCallback = nil
        completion()
    }
}


// MARK: - TVONotificaitonDelegate
extension CallConnectivityManager: NotificationDelegate {
    func callInviteReceived(callInvite: CallInvite) {
        NSLog("callInviteReceived:")
        
        let callerInfo: TVOCallerInfo = callInvite.callerInfo
        if let verified: NSNumber = callerInfo.verified {
            if verified.boolValue {
                NSLog("Call invite received from verified caller number!")
            }
        }
        
        let from = (callInvite.from ?? "TokTiv").replacingOccurrences(of: "client:", with: "")

        reportIncomingCall(from: from, uuid: callInvite.uuid)
        activeCallInvites[callInvite.uuid.uuidString] = callInvite
        
        self.currentCallDirection = "Inbound"
    }
    
    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        NSLog("cancelledCallInviteCanceled:error:, error: \(error.localizedDescription)")
        
        guard let activeCallInvites = activeCallInvites, !activeCallInvites.isEmpty else {
            NSLog("No pending call invite")
            return
        }
        
        let callInvite = activeCallInvites.values.first { invite in invite.callSid == cancelledCallInvite.callSid }
        
        if let callInvite = callInvite {
            performEndCallAction(uuid: callInvite.uuid)
        }
    }
}


extension CallConnectivityManager: CallDelegate {
    func callDidStartRinging(call: Call) {
        NSLog("callDidStartRinging:")
        
        self.connectivityDelegate?.updatePlaceCallButton(UIColor.lightGray)
        self.observer.inCall = true
      
        if playCustomRingback {
            playRingback()
        }
    }
    
    func callDidConnect(call: Call) {
        NSLog("callDidConnect:")
        
        if playCustomRingback {
            stopRingback()
        }
        
        if let callKitCompletionCallback = callKitCompletionCallback {
            callKitCompletionCallback(true)
        }
        
        self.connectivityDelegate?.updatePlaceCallButton(UIColor.systemRed)
        self.observer.inCall = true
        
        self.connectivityDelegate?.toggleAudioRoute(toSpeaker: false)
        self.connectivityDelegate?.muteCurrentCall(enabled: false)
        
        if let validDirection = self.currentCallDirection, activeCall != nil  {
            print(activeCall?.sid ?? "*******")
            self.connectivityDelegate?.incomingCallStatusConnectivity(status: true, direction:"\(validDirection)")
        }
        
    }
    
    func call(call: Call, isReconnectingWithError error: Error) {
        NSLog("call:isReconnectingWithError:")
        
        self.connectivityDelegate?.updatePlaceCallButton(UIColor.lightGray)
        self.observer.inCall = true
    }
    
    func callDidReconnect(call: Call) {
        NSLog("callDidReconnect:")
        
        self.connectivityDelegate?.updatePlaceCallButton(UIColor.systemRed)
        self.observer.inCall = true
    }
    
    func callDidFailToConnect(call: Call, error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")
        let description = "\(error)"
        if UIApplication.shared.applicationState == .active {
            NotificationBanner(title: nil, subtitle: description, leftView: nil, rightView: nil, style: .danger, colors: nil).show()
        }
        
        if let completion = callKitCompletionCallback {
            completion(false)
        }
        
        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)
        }

        callDisconnected(call: call)
    }
    
    func callDidDisconnect(call: Call, error: Error?) {
        if let error = error {
            NSLog("Call failed: \(error.localizedDescription)")
            
        } else {
            NSLog("Call disconnected")
        }
        
        if !userInitiatedDisconnect {
            var reason = CXCallEndedReason.remoteEnded
            
            if error != nil {
                reason = .failed
            }
            
            if let provider = callKitProvider {
                provider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
            }
        }

        callDisconnected(call: call)
    }
    
    func callDisconnected(call: Call) {
        
        if let appdelegate = UIApplication.shared.delegate as? AppDelegate, self.currentCallDirection == "Inbound" {
            UserDefaults.standard.setValue(Date(), forKey: AppConstants.LAST_INBOUND_CALL_DATE)
            UserDefaults.standard.synchronize()
            appdelegate.callManager.startSuspensionTimer()
        }
        
        if call == activeCall {
            activeCall = nil
        }
        
        activeCalls.removeValue(forKey: call.uuid!.uuidString)
        
        userInitiatedDisconnect = false
        
        if playCustomRingback {
            stopRingback()
        }
        
        self.connectivityDelegate?.updatePlaceCallButton(UIColor.systemGreen)
        self.observer.inCall = false
        
        self.connectivityDelegate?.incomingCallStatusConnectivity(status: false, direction: self.currentCallDirection ?? "")
       
    }
    
    func call(call: Call, didReceiveQualityWarnings currentWarnings: Set<NSNumber>, previousWarnings: Set<NSNumber>) {
        
        var warningsIntersection: Set<NSNumber> = currentWarnings
        warningsIntersection = warningsIntersection.intersection(previousWarnings)
        
        var newWarnings: Set<NSNumber> = currentWarnings
        newWarnings.subtract(warningsIntersection)
        if newWarnings.count > 0 {
            qualityWarningsUpdatePopup(newWarnings, isCleared: false)
        }
        
        var clearedWarnings: Set<NSNumber> = previousWarnings
        clearedWarnings.subtract(warningsIntersection)
        if clearedWarnings.count > 0 {
            qualityWarningsUpdatePopup(clearedWarnings, isCleared: true)
        }
    }
    
    func qualityWarningsUpdatePopup(_ warnings: Set<NSNumber>, isCleared: Bool) {
        var popupMessage: String = "Warnings detected: "
        if isCleared {
            popupMessage = "Warnings cleared: "
        }
        
        let mappedWarnings: [String] = warnings.map { number in warningString(Call.QualityWarning(rawValue: number.uintValue)!)}
        popupMessage += mappedWarnings.joined(separator: ", ")
        
        print("***** " + popupMessage)
    }
    
    func warningString(_ warning: Call.QualityWarning) -> String {
        switch warning {
        case .highRtt: return "high-rtt"
        case .highJitter: return "high-jitter"
        case .highPacketsLostFraction: return "high-packets-lost-fraction"
        case .lowMos: return "low-mos"
        case .constantAudioInputLevel: return "constant-audio-input-level"
        default: return "Unknown warning"
        }
    }
    
    
    // MARK: Ringtone
    
    func playRingback() {
        let ringtonePath = URL(fileURLWithPath: Bundle.main.path(forResource: "ringtone", ofType: "wav")!)
        
        do {
            ringtonePlayer = try AVAudioPlayer(contentsOf: ringtonePath)
            ringtonePlayer?.delegate = self
            ringtonePlayer?.numberOfLoops = -1
            
            ringtonePlayer?.volume = 1.0
            ringtonePlayer?.play()
        } catch {
            NSLog("Failed to initialize audio player")
        }
    }
    
    func stopRingback() {
        guard let ringtonePlayer = ringtonePlayer, ringtonePlayer.isPlaying else { return }
        
        ringtonePlayer.stop()
    }
}

// MARK: - CXProviderDelegate
extension CallConnectivityManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        NSLog("providerDidReset:")
        audioDevice.isEnabled = false
    }

    func providerDidBegin(_ provider: CXProvider) {
        NSLog("providerDidBegin")
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("provider:didActivateAudioSession:")
        audioDevice.isEnabled = true
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        NSLog("provider:didDeactivateAudioSession:")
        audioDevice.isEnabled = false
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("provider:timedOutPerformingAction:")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("provider:performStartCallAction:")
                
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        
        performVoiceCall(uuid: action.callUUID, client: "") { success in
            if success {
                NSLog("performVoiceCall() successful")
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            } else {
                NSLog("performVoiceCall() failed")
            }
        }
        
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NSLog("provider:performAnswerCallAction:")
        
        performAnswerVoiceCall(uuid: action.callUUID) { success in
            if success {
                NSLog("performAnswerVoiceCall() successful")
            } else {
                NSLog("performAnswerVoiceCall() failed")
            }
        }
        
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")
        
        if let invite = activeCallInvites[action.callUUID.uuidString] {
            invite.reject()
            activeCallInvites.removeValue(forKey: action.callUUID.uuidString)
        } else if let call = activeCalls[action.callUUID.uuidString] {
            call.disconnect()
        } else {
            NSLog("Unknown UUID to perform end-call action with")
        }

        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provider:performSetHeldAction:")
        
        if let call = activeCalls[action.callUUID.uuidString] {
            call.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        NSLog("provider:performSetMutedAction:")

        if let call = activeCalls[action.callUUID.uuidString] {
            call.isMuted = action.isMuted
            action.fulfill()
        } else {
            action.fail()
        }
    }

    
    // MARK: Call Kit Actions
    func performStartCallAction(uuid: UUID, handle: String) {
        guard let provider = callKitProvider else {
            NSLog("CallKit provider not available")
            return
        }
        
        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }

            NSLog("StartCallAction transaction request successful")

            let callUpdate = CXCallUpdate()
            
            callUpdate.remoteHandle = callHandle
            callUpdate.supportsDTMF = true
            callUpdate.supportsHolding = true
            callUpdate.supportsGrouping = false
            callUpdate.supportsUngrouping = false
            callUpdate.hasVideo = false

            provider.reportCall(with: uuid, updated: callUpdate)
        }
    }

    func reportIncomingCall(from: String, uuid: UUID) {
        guard let provider = callKitProvider else {
            NSLog("CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()
        
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false

        provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if let error = error {
                NSLog("Failed to report incoming call successfully: \(error.localizedDescription).")
            } else {
                NSLog("Incoming call successfully reported.")
            }
        }
    }

    func performEndCallAction(uuid: UUID) {

        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
            } else {
                NSLog("EndCallAction transaction request successful")
            }
        }
    }
    
    func performVoiceCall(uuid: UUID, client: String?, completionHandler: @escaping (Bool) -> Void) {
        guard let accessToken = fetchAccessToken() else {
            completionHandler(false)
            return
        }
        

        let validInput = self.callNumber
        
        let fromNumber = self.observer.loginViewModel.defaultPhoneNumber
        let twimlParamCallerAgentValue = self.observer.loginViewModel.userProfile?.providerCode ?? ""
        
        print("\n\n******************\n\(twimlParamTo):\(validInput)\n\(twimlParamFrom):\(fromNumber)\n\(twimlParamCallerAgent):\(twimlParamCallerAgentValue)\n******************\n\n")
        let connectOptions = ConnectOptions(accessToken: accessToken) { builder in
            builder.params = [
                twimlParamTo: validInput,
                twimlParamFrom: fromNumber,
                twimlParamCallerAgent: twimlParamCallerAgentValue
            ]
            builder.uuid = uuid
        }
        
        let call = TwilioVoice.connect(options: connectOptions, delegate: self)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler
    }
    
    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        guard let callInvite = activeCallInvites[uuid.uuidString] else {
            NSLog("No CallInvite matches the UUID")
            return
        }
        
        let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
            builder.uuid = callInvite.uuid
        }
        
        let call = callInvite.accept(options: acceptOptions, delegate: self)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler
        
        activeCallInvites.removeValue(forKey: uuid.uuidString)
        
        guard #available(iOS 13, *) else {
            incomingPushHandled()
            return
        }
    }
}


// MARK: - AVAudioPlayerDelegate
extension CallConnectivityManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            NSLog("Audio player finished playing successfully");
        } else {
            NSLog("Audio player finished playing with some error");
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            NSLog("Decode error occurred: \(error.localizedDescription)")
        }
    }
}
