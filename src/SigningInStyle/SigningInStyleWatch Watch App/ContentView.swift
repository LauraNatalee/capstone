import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var state = ""
    private let speaker = Speaker()
    
    @Published var data = "" //
    
    func demo_process(accelerometerData: CMAcceleration) {
        let accX = accelerometerData.x
        let speedX = 0.75
        let speedY = 0.75
        let speedZ = 1.75
        let accY = accelerometerData.y
        let accZ = accelerometerData.z
        let prevState = self.state
        if (abs(accX) > speedX && abs(accY) > speedY) {
            print("sorry")
            self.state = "sorry"
        } else if (abs(accY) > speedY && abs(accZ) > speedZ) {
            print("thank you")
            self.state = "thank you"
        }

        if prevState != self.state {
            self.speaker.stopSpeaking()
            self.speaker.speak(self.state)
        }
            
        DispatchQueue.main.async {
            if (abs(accX) > speedX && abs(accY) > speedY) {
                self.data = "sorry"
            } else if (abs(accY) > speedY && abs(accZ) > speedZ) {
                self.data = "thank you"
            }
        }
    }
    
    func process(accelerometerData: CMAcceleration) {
        print("Acc: \(accelerometerData)")
    }
    
    func process(rotationRate: CMRotationRate) {
        print("Gyro: \(rotationRate)")
    }

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            fatalError("No device motion available")
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // Adjust as needed
        
        motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
            guard let motion = motion else {
                fatalError("No motion data")
            }
            
            //self.demo_process(accelerometerData: motion.userAcceleration)
            self.process(accelerometerData: motion.userAcceleration)
            self.process(rotationRate: motion.rotationRate)
        }
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}


struct ContentView: View {
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        VStack {
            Text("ASL Detection")
            
            Text(motionManager.data) //Motion Data Stream
            
            Button("Start") {
                motionManager.startMotionUpdates()
            }
            Button("Stop") {
                motionManager.stopMotionUpdates()
            }
        }
    }
}
