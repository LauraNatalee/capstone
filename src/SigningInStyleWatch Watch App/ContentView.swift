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
    
    @Published var data = "" //

    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable { // }&& motionManager.isGyroAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // Adjust as needed
            // motionManager.gyroUpdateInterval = 0.1 // Adjust as needed

            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let accelerometerData = data {
                    print("Accelerometer: \(accelerometerData.acceleration)")
                    
                    DispatchQueue.main.async { //
                        self.data = "\(accelerometerData.acceleration.x)" //
                    } //
                    
                }
            }

            /* motionManager.startGyroUpdates(to: .main) { (data, error) in
                if let gyroData = data {
                    print("Gyroscope: \(gyroData.rotationRate)")
                }
            } */
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
