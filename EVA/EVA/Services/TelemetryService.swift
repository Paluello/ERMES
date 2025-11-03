//
//  TelemetryService.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import CoreLocation
import Combine

/// Servizio per acquisizione e invio telemetria GPS/IMU
@MainActor
class TelemetryService: ObservableObject {
    private let locationManager = LocationManager()
    private let motionManager = MotionManager()
    private let apiClient: ERMESAPIClient
    
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 0.1 // 10 Hz
    
    @Published var isRunning = false
    @Published var lastTelemetry: TelemetryData?
    
    private var sourceId: String?
    
    init(apiClient: ERMESAPIClient) {
        self.apiClient = apiClient
    }
    
    func start(sourceId: String) {
        self.sourceId = sourceId
        
        // Richiedi permessi e avvia acquisizione
        locationManager.requestAuthorization()
        locationManager.startUpdatingLocation()
        motionManager.startUpdates()
        
        // Avvia timer per invio telemetria
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendTelemetry()
            }
        }
        
        isRunning = true
    }
    
    func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        locationManager.stopUpdatingLocation()
        motionManager.stopUpdates()
        
        // Disconnettere sorgente
        if let sourceId = sourceId {
            Task {
                try? await apiClient.disconnectSource(sourceId: sourceId)
            }
        }
        
        isRunning = false
    }
    
    private func sendTelemetry() async {
        guard let sourceId = sourceId,
              let location = locationManager.currentLocation else {
            return
        }
        
        // Calcola camera_tilt e camera_pan da orientamento telefono
        // camera_tilt = -pitch (negativo perché pitch positivo = telefono verso alto)
        // camera_pan = heading (direzione bussola)
        let cameraTilt = -motionManager.pitch
        let cameraPan = locationManager.heading ?? 0.0
        
        let telemetry = TelemetryData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            heading: locationManager.heading,
            pitch: motionManager.pitch,
            roll: motionManager.roll,
            yaw: motionManager.yaw,
            velocityX: location.speed * cos(location.course * .pi / 180.0),
            velocityY: location.speed * sin(location.course * .pi / 180.0),
            velocityZ: nil, // Non disponibile da GPS
            cameraTilt: cameraTilt,
            cameraPan: cameraPan
        )
        
        lastTelemetry = telemetry
        
        // Invia al backend
        do {
            try await apiClient.updateTelemetry(sourceId: sourceId, telemetry: telemetry)
        } catch {
            print("Errore invio telemetria: \(error)")
        }
    }
}

