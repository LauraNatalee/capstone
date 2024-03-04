import Combine
import CoreML
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
    let model: SignRecognition
    let speaker = Speaker()
    
    var episodes: [[RecordingSnapshot]] = []
    var recordingData: [RecordingSnapshot] = []
    @Published var recording = false
    
    init() {
        self.model = try! SignRecognition(configuration: MLModelConfiguration())
        self.startMotionUpdates()
    }
    
    func classify(recording: [RecordingSnapshot]) {
        let timesteps = recording.count
        let accX = recording.map { ($0.accX) }
        let accY = recording.map { ($0.accY) }
        let accZ = recording.map { ($0.accZ) }
        let gyroX = recording.map { ($0.gyroX) }
        let gyroY = recording.map { ($0.gyroY) }
        let gyroZ = recording.map { ($0.gyroZ) }
        var recurrentState = try! MLMultiArray(shape: [400], dataType: .float64)
        for i in 0..<400 {
            recurrentState[i] = 0
        }

        let accXML = try! MLMultiArray(shape: [25], dataType: .float64)
        let accYML = try! MLMultiArray(shape: [25], dataType: .float64)
        let accZML = try! MLMultiArray(shape: [25], dataType: .float64)
        let gyroXML = try! MLMultiArray(shape: [25], dataType: .float64)
        let gyroYML = try! MLMultiArray(shape: [25], dataType: .float64)
        let gyroZML = try! MLMultiArray(shape: [25], dataType: .float64)
        var labelProbabilities: [String: Double] = [:]
        let chunks = timesteps / 25
        for i in 0..<chunks {
            let start = i * 25
            for idx in 0..<25 {
                accXML[idx] =  NSNumber(value: accX[start + idx])
                accYML[idx] =  NSNumber(value: accY[start + idx])
                accZML[idx] =  NSNumber(value: accZ[start + idx])
                gyroXML[idx] = NSNumber(value: gyroX[start + idx])
                gyroYML[idx] = NSNumber(value: gyroY[start + idx])
                gyroZML[idx] = NSNumber(value: gyroZ[start + idx])
            }
            let result = try! self.model.prediction(accX: accXML, accY: accYML, accZ: accZML, gyroX: gyroXML, gyroY: gyroYML, gyroZ: gyroZML, stateIn: recurrentState)
            recurrentState = result.stateOut
            labelProbabilities = result.labelProbability
        }
        print(labelProbabilities)
        let guess = labelProbabilities.max {
            $0.value < $1.value
        }!.key
        speaker.speak(guess)
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
            self.classify(recording: x)
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
