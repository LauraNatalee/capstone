//
//  ContentView.swift
//  SigningInStyleWatch Watch App
//
//  Created by Simone Ocvirk on 2023-11-19.
//

import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var state = ""
    private let speaker = Speaker()
    
    @Published var data = "" //

    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable { // }&&
        //if motionManager.isGyroAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // Adjust as needed
            // motionManager.gyroUpdateInterval = 0.1 // Adjust as needed

            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let accelerometerData = data {
                    //print("Accelerometer: \(accelerometerData.acceleration)")
                    let accX = accelerometerData.acceleration.x
                    let speedX = 0.75
                    let speedY = 0.75
                    let speedZ = 1.75
                    let accY = accelerometerData.acceleration.y
                    let accZ = accelerometerData.acceleration.z
                    let prevState = self.state
                    if (abs(accX) > speedX && abs(accY) > speedY) {
                        print("sorry")
                        self.state = "sorry"
                    } else if (abs(accY) > speedY && abs(accZ) > speedZ) {
                        print("thank you")
                        self.state = "thank you"
                    } /*else if (abs(accZ) > speedZ && abs(accX) > speedX) {
                        print("Z & X")
                    } else if (abs(accX) > speedX) {
                        print("moving in x")
                    } else if (abs(accY) > speedY) {
                        print("moving in y")
                    } else if (abs(accZ) > speedZ) {
                        print("moving in z")
                    } */
                    
                    if prevState != self.state {
                        self.speaker.stopSpeaking()
                        self.speaker.speak(self.state)
                    }
                        
                    DispatchQueue.main.async { //
                        if (abs(accX) > speedX && abs(accY) > speedY) {
                            self.data = "sorry"
                        } else if (abs(accY) > speedY && abs(accZ) > speedZ) {
                            self.data = "thank you"
                        }
                    }
                }
            }

            /*motionManager.startGyroUpdates(to: OperationQueue, withHandler: CMGyroHandler) { (data, error) in
                if let gyroData = data {
                    print("Gyroscope: \(gyroData.rotationRate)")
                    
                    DispatchQueue.main.async { //
                        self.data = "\(gyroData.rotationRate.x)" //
                    } //
                }
            }*/
        } else {
            print("Not working")
        }
    }

    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
}


struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    
    //@ObservedObject private var motionManager = MotionManager() //

    var body: some View {
        VStack {
            Text("Motion Data Stream")
            
            Text(motionManager.data) //
            
            Button("Start") {
                motionManager.startMotionUpdates()
            }
            Button("Stop") {
                motionManager.stopMotionUpdates()
            }
        }
    }
}
