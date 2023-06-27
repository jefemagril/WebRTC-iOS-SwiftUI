//
//  ContentView.swift
//  WebRTC-iOS-SwiftUI
//
//  Created by Jeff Magill on 6/7/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var webRTC = WebRTCService()
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
                Text("\(webRTC.signalingConnected ? "Connected" : "Not connected")")
                        .foregroundColor(webRTC.signalingConnected ? .green : .red)
                Text("Local SDP: \(hasLocalSdp ? "✅" : "❌")")
                Text("Local Candidates: \(webRTC.localCandidateCount)")
                Text("Remote SDP: \(webRTC.hasRemoteSdp ? "✅" : "❌")")
                Text("Remote Candidates: \(webRTC.remoteCandidateCount)")
                
                Spacer()
                
                Group {
                    Text("WebRTC Status:")
                    Text(webRTC.webRTCStatus)
                        .bold()
                        .foregroundColor(webRTC.webRTCStatusTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.title3)
                
                Spacer()
                
                HStack {
                    Button(muted ? "Mute: on" : "Mute: off") {
                        if muted {
                            webRTC.unmuteAudio()
                        } else {
                            webRTC.muteAudio()
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
                            webRTC.sendData(dataToSend)
                        }
                    } message: {
                        Text("This will be transferred over WebRTC data channel")
                    }
                    .alert(isPresented: $webRTC.presentingData) {
                        Alert(
                            title: Text("Message from WebRTC"),
                            message: Text(webRTC.dataMessage)
                        )
                    }
                    .onAppear {
                        print(webRTC.dataMessage)
                    }
                }
                HStack {
                    Button(speakerOn ? "Speaker: On" : "Speaker: Off") {
                        if speakerOn {
                            webRTC.speakerOff()
                        } else {
                            webRTC.speakerOn()
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
                webRTC.offer { (sdp) in
                    hasLocalSdp = true
                    webRTC.send(sdp: sdp)
                }
            }
            BigButton("Send answer") {
                webRTC.answer { (localSdp) in
                    hasLocalSdp = true
                    webRTC.send(sdp: localSdp)
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
