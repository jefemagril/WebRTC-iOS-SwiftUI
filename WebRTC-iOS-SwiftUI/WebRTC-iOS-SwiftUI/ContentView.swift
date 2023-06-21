//
//  ContentView.swift
//  WebRTC-iOS-SwiftUI
//
//  Created by Jeff Magill on 6/7/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var webRTCClient = WebRTCClient()
    @State var hasLocalSdp = false
    @State var muted = false
    @State var speakerOn = false
    @State var showingDataInputAlert = false
    @State var dataToSendStr = ""
    
    var body: some View {
        VStack {
            Text("WebRTC SwiftUI Demo")
                .font(.title)
                .padding()
            VStack(alignment: .leading, spacing: 20) {
                Text("Signaling status: ") +
                Text("\(webRTCClient.signalingConnected ? "Connected" : "Not connected")")
                        .foregroundColor(webRTCClient.signalingConnected ? .green : .red)
                Text("Local SDP: \(hasLocalSdp ? "✅" : "❌")")
                Text("Local Candidates: \(webRTCClient.localCandidateCount)")
                Text("Remote SDP: \(webRTCClient.hasRemoteSdp ? "✅" : "❌")")
                Text("Remote Candidates: \(webRTCClient.remoteCandidateCount)")
                
                Spacer()
                
                Group {
                    Text("WebRTC Status:")
                    Text(webRTCClient.webRTCStatus)
                        .bold()
                        .foregroundColor(webRTCClient.webRTCStatusTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.title3)
                
                Spacer()
                
                HStack {
                    Button(muted ? "Mute: on" : "Mute: off") {
                        if muted {
                            webRTCClient.unmuteAudio()
                        } else {
                            webRTCClient.muteAudio()
                        }
                        muted.toggle()
                    }
                    Spacer()
                    Button("Send data") {
                        showingDataInputAlert.toggle()
                    }
                    .alert("Send a message to the other peer", isPresented: $showingDataInputAlert) {
                        TextField("Message to send", text: $dataToSendStr)
                        Button("Cancel") {
                            showingDataInputAlert = false
                        }
                        Button("Send") {
                            guard let dataToSend = dataToSendStr.data(using: .utf8) else {
                                return
                            }
                            webRTCClient.sendData(dataToSend)
                        }
                    } message: {
                        Text("This will be transferred over WebRTC data channel")
                    }
                    .alert("Message from WebRTC", isPresented: $webRTCClient.presentingData) {
                        Text(webRTCClient.dataMessage)
                    }
                }
                HStack {
                    Button(speakerOn ? "Speaker: On" : "Speaker: Off") {
                        if speakerOn {
                            webRTCClient.speakerOff()
                        } else {
                            webRTCClient.speakerOn()
                        }
                        speakerOn.toggle()
                    }
                    Spacer()
                    Button("Video") {
                        print("video")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            BigButton("Send offer") {
                webRTCClient.offer { (sdp) in
                    hasLocalSdp = true
                    webRTCClient.signalClient.send(sdp: sdp)
                }
            }
            BigButton("Send answer") {
                webRTCClient.answer { (localSdp) in
                    hasLocalSdp = true
                    webRTCClient.signalClient.send(sdp: localSdp)
                }
            }
        }
        .padding()
    }
}

struct BigButton: View {
    let text: String
    let action: () -> Void
    
    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(maxWidth: .infinity, maxHeight: 50)
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .contentShape(Rectangle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
