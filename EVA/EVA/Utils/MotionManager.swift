//
//  MotionManager.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import CoreMotion
import Combine

/// Wrapper per CoreMotion per gestione IMU (accelerometro, giroscopio)
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var yaw: Double = 0.0
    
    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 Hz
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else {
                print("Motion update error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            // Converti attitudine (quaternione) a angoli Euler
            let attitude = motion.attitude
            self?.pitch = attitude.pitch * 180.0 / .pi // Converti a gradi
            self?.roll = attitude.roll * 180.0 / .pi
            self?.yaw = attitude.yaw * 180.0 / .pi
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

