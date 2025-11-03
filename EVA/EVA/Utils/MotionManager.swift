//
//  MotionManager.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import CoreMotion
import Combine
import UIKit

/// Wrapper per CoreMotion per gestione IMU (accelerometro, giroscopio)
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var yaw: Double = 0.0
    @Published var hasError: Bool = false
    @Published var errorMessage: String?
    
    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            DispatchQueue.main.async {
                self.hasError = true
                self.errorMessage = "Sensori movimento non disponibili"
            }
            print("⚠️ Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 Hz
        
        // NOTA: Su iOS Simulator potresti vedere warning di sistema come:
        // - "Error reading file com.apple.CoreMotion.plist" (Code 257)
        // - "Fig signalled err=-12710" o "err=-17281"
        // Questi sono warning innocui del sistema iOS e vengono ignorati silenziosamente.
        // Non influenzano il funzionamento dell'app e non appaiono su dispositivi fisici.
        
        // Prova prima con xArbitraryZVertical (più compatibile, non richiede magnetometro)
        // Questo evita errori di permessi con CoreMotion.plist
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, error in
            guard let self = self else { return }
            
            if let error = error {
                let nsError = error as NSError?
                
                // Ignora completamente errori comuni su Simulator (sono solo warning del sistema)
                if let nsError = nsError {
                    // Errore CoreMotion.plist (Code 257) - comune su Simulator
                    if nsError.domain == "NSCocoaErrorDomain" && nsError.code == 257 {
                        // Silenziosamente ignora - è solo un warning del sistema
                        return
                    }
                    
                    // Errori Fig/AVFoundation comuni su Simulator (-12710, -17281)
                    if nsError.code == -17281 || nsError.code == -12710 {
                        // Su Simulator questi errori sono normali e possono essere ignorati
                        if UIDevice.isSimulator {
                            // Silenziosamente ignora su Simulator
                            return
                        }
                        
                        // Su dispositivo fisico, prova con riferimento alternativo
                        self.motionManager.stopDeviceMotionUpdates()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, error in
                                guard let motion = motion, error == nil else {
                                    // Se anche questo fallisce, ignora silenziosamente su Simulator
                                    if UIDevice.isSimulator {
                                        return
                                    }
                                    print("⚠️ Motion fallback failed")
                                    return
                                }
                                self?.updateMotionValues(motion: motion)
                            }
                        }
                        return
                    }
                }
                
                // Per altri errori, gestisci normalmente ma solo se non siamo su Simulator
                if !UIDevice.isSimulator {
                    DispatchQueue.main.async {
                        self.hasError = true
                        self.errorMessage = "Errore sensori: \(error.localizedDescription)"
                    }
                    print("⚠️ Motion update error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let motion = motion else {
                return
            }
            
            self.updateMotionValues(motion: motion)
        }
    }
    
    private func updateMotionValues(motion: CMDeviceMotion) {
        // Converti attitudine (quaternione) a angoli Euler
        let attitude = motion.attitude
        DispatchQueue.main.async {
            self.pitch = attitude.pitch * 180.0 / .pi // Converti a gradi
            self.roll = attitude.roll * 180.0 / .pi
            self.yaw = attitude.yaw * 180.0 / .pi
            self.hasError = false
            self.errorMessage = nil
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

