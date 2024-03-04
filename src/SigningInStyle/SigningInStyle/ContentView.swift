//
//  ContentView.swift
//  SigningInStyle
//
//  Created by Simone Ocvirk on 2023-11-19.
//

import Combine
import SwiftUI
import WatchConnectivity

class Comms: NSObject, ObservableObject, WCSessionDelegate {
    let session: WCSession
    @Published var recording = false
    @Published var hasWatchConnection = false
    
    override init() {
        self.session = WCSession.default
        super.init()

        self.session.delegate = self
        self.session.activate()
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            fatalError("\(error)")
        }
        guard self.session == session else {
            fatalError("Inconsistent session state")
        }
        guard activationState == WCSessionActivationState.activated else {
            fatalError("\(activationState)")
        }
        self.hasWatchConnection = self.session.isReachable
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let currentWatchStatus = message["currentWatchStatus"] as? Bool else {
            fatalError("Invalid message: \(message)")
        }
        DispatchQueue.main.sync {
            self.recording = currentWatchStatus
            print("Updated iOS State to Watch state")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        guard self.session == session else {
            fatalError("Inconsistent session state")
        }
        self.hasWatchConnection = false
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        guard self.session == session else {
            fatalError("Inconsistent session state")
        }
        self.hasWatchConnection = false
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {}
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        self.hasWatchConnection = session.isReachable
    }
    
    func notifyStartRecording() {
        assert(!self.recording)
        //DispatchQueue.main.sync {
        self.recording = true
        //}
        self.session.sendMessage(["status": "start"], replyHandler: nil)
    }
    
    func notifyStopRecording() {
        assert(self.recording)
        //DispatchQueue.main.sync {
        self.recording = false
        //}
        self.session.sendMessage(["status": "stop"], replyHandler: nil)
    }
    
    func notifyExport() {
        self.session.sendMessage(["status": "export"], replyHandler: nil)
    }
}

struct ContentView: View {
    @ObservedObject private var comms = Comms()
    
    var body: some View {
        VStack(spacing: 40) {
            if comms.hasWatchConnection {
                Text("Connected to Watch")
                if comms.recording {
                    Button {
                        self.comms.notifyStopRecording()
                    } label: {
                        Text("Stop Recording")
                    }
                } else {
                    Button {
                        self.comms.notifyStartRecording()
                    } label: {
                        Text("Start Recording")
                    }
                }
                Button {
                    self.comms.notifyExport()
                } label: {
                    Text("Export")
                }
            } else {
                Text("Not connected to Watch")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
