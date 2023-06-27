//
//  WebRTC.swift
//  WebRTC-iOS-SwiftUI
//
//  Created by Jeff Magill on 6/21/23.
//

import Foundation
import SwiftUI
import WebRTC

class WebRTCService: ObservableObject {
    private var signalClient: SignalingClient
    private var webRTCClient: WebRTCClient
    
    @Published var signalingConnected = false
    @Published var hasRemoteSdp = false
    @Published var remoteCandidateCount = 0
    @Published var localCandidateCount = 0
    @Published var webRTCStatus = "New"
    @Published var webRTCStatusTextColor = Color.black
    @Published var presentingData = false
    
    @Published var dataMessage: String = "" {
        didSet {
            presentingData = true
        }
    }
    
    init() {
        self.webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
        self.signalClient = SignalingClient(
            webSocket: NativeWebSocket(url: Config.default.signalingServerUrl)
        )
        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
        self.signalClient.connect()
    }

    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        self.webRTCClient.offer { (sdp) in
            completion(sdp)
        }
    }

    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void)  {
        self.webRTCClient.answer { (sdp) in
            completion(sdp)
        }
    }

    func send(sdp rtcSdp: RTCSessionDescription) {
        self.signalClient.send(sdp: rtcSdp)
    }

    func muteAudio() {
        self.webRTCClient.muteAudio()
    }

    func unmuteAudio() {
        self.webRTCClient.unmuteAudio()
    }

    func sendData(_ data: Data) {
        self.webRTCClient.sendData(data)
    }

    func speakerOn() {
        self.webRTCClient.speakerOn()
    }

    func speakerOff() {
        self.webRTCClient.speakerOff()
    }
}

extension WebRTCService: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        DispatchQueue.main.async {
            self.signalingConnected = true
        }
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        DispatchQueue.main.async {
            self.signalingConnected = false
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            DispatchQueue.main.async {
                self.hasRemoteSdp = true
            }
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        self.webRTCClient.set(remoteCandidate: candidate) { error in
            print("Received remote candidate")
            DispatchQueue.main.async {
                self.remoteCandidateCount += 1
            }
        }
    }
}

extension WebRTCService: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        DispatchQueue.main.async {
            self.localCandidateCount += 1
        }
        self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: Color
        switch state {
        case .connected, .completed:
            textColor = .green
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webRTCStatus = state.description.capitalized
            self.webRTCStatusTextColor = textColor
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        DispatchQueue.main.async {
            self.dataMessage = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
        }
    }
}
