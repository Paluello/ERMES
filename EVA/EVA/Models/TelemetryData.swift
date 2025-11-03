//
//  TelemetryData.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation

/// Modello dati telemetria per invio al backend ERMES
struct TelemetryData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let heading: Double?
    let pitch: Double?
    let roll: Double?
    let yaw: Double?
    let velocityX: Double?
    let velocityY: Double?
    let velocityZ: Double?
    let cameraTilt: Double?
    let cameraPan: Double?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case altitude
        case heading
        case pitch
        case roll
        case yaw
        case velocityX = "velocity_x"
        case velocityY = "velocity_y"
        case velocityZ = "velocity_z"
        case cameraTilt = "camera_tilt"
        case cameraPan = "camera_pan"
    }
}

