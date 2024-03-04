import Combine
import CoreMotion
import SwiftUI
import WatchConnectivity

struct RecordingSnapshot {
    let accX: Double
    let accY: Double
    let accZ: Double
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double
}

extension RecordingSnapshot: CustomStringConvertible {
    var description: String {
        "\(accX),\(accY),\(accZ),\(gyroX),\(gyroY),\(gyroZ)"
    }
}

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    var episodes: [[RecordingSnapshot]] = []
    var recordingData: [RecordingSnapshot] = []
    @Published var recording = false
    
    init() {
        self.startMotionUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            fatalError("No device motion available")
        }
        
        motionManager.deviceMotionUpdateInterval = 1 / 100 // 100Hz
        
        motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
            guard let motion = motion else {
                fatalError("No motion data")
            }
            guard self.recording else {
                return
            }
            let snapshot = RecordingSnapshot(
                accX: motion.userAcceleration.x,
                accY: motion.userAcceleration.y,
                accZ: motion.userAcceleration.z,
                gyroX: motion.rotationRate.x,
                gyroY: motion.rotationRate.y,
                gyroZ: motion.rotationRate.z
            )
            self.recordingData.append(snapshot)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func startRecording() {
        DispatchQueue.main.sync {
            self.recordingData = []
            self.recording = true
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.sync {
            self.recording = false
            let x = self.recordingData
            self.episodes.append(x)
            self.recordingData = []
        }
    }
    
    func export() {
        DispatchQueue.main.sync {
            let x = self.episodes.map { episode in
                episode.map { $0.description }.joined(separator: "|||")
            }.joined(separator: "~~~")
            print(x)
            self.episodes = []
        }
    }
}

enum MotionRecordingStatus {
    case start, stop
}

class Comms: NSObject, ObservableObject, WCSessionDelegate {
    let recordingStatusChannel = PassthroughSubject<MotionRecordingStatus, Never>()
    
    let session: WCSession
    let motionManager: MotionManager
    @Published var hasPhoneConnection = false
    
    init(motionManager: MotionManager) {
        self.session = WCSession.default
        self.motionManager = motionManager
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
        self.hasPhoneConnection = self.session.isReachable
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let status = message["status"] as? String else {
            fatalError("Invalid message: \(message)")
        }
        switch status {
        case "start":
            self.motionManager.startRecording()
        case "stop":
            self.motionManager.stopRecording()
        case "export":
            self.motionManager.export()
        default:
            fatalError("Invalid status: \(status)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if !self.hasPhoneConnection && session.isReachable {
            session.sendMessage(["currentWatchStatus": self.motionManager.recording], replyHandler: nil)
        }
        self.hasPhoneConnection = session.isReachable
    }
}


struct ContentView: View {
    @ObservedObject private var motionManager: MotionManager
    @ObservedObject private var comms: Comms
    
    init() {
        let motionManager = MotionManager()
        self.motionManager = motionManager
        self.comms = Comms(motionManager: motionManager)
    }

    var body: some View {
        ZStack {
            if motionManager.recording {
                Color.green
            } else {
                Color.red
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
