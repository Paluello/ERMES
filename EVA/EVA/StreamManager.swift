//
//  StreamManager.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import AVFoundation
import UIKit
import Combine

/// Manager principale per coordinare tutti i servizi di streaming
@MainActor
class StreamManager: ObservableObject {
    @Published var isStreaming = false
    @Published var isConnecting = false
    
    var config = StreamConfig()
    let videoCapture = VideoCaptureService()
    let rtmpStream = RTMPStreamService()
    let telemetryService: TelemetryService
    
    private let apiClient: ERMESAPIClient
    private let sourceId: String
    
    init() {
        // Genera UUID device per source_id
        sourceId = UUID.deviceUUID.uuidString
        
        // Inizializza API client
        apiClient = ERMESAPIClient(baseURL: config.backendURL, apiKey: config.apiKey)
        
        // Inizializza telemetry service
        telemetryService = TelemetryService(apiClient: apiClient)
        
        // Setup video capture callback
        videoCapture.onFrameCaptured = { [weak self] sampleBuffer in
            self?.rtmpStream.appendVideoSampleBuffer(sampleBuffer)
        }
    }
    
    func startStreaming() async {
        guard !isStreaming && !isConnecting else { return }
        
        isConnecting = true
        
        // Richiedi permessi camera
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus != .authorized {
            await AVCaptureDevice.requestAccess(for: .video)
        }
        
        // Setup video capture
        videoCapture.setup(config: config)
        videoCapture.start()
        
        // Estrai host e porta dall'URL backend
        let backendHost: String
        let rtmpPort: Int = 1935 // Porta RTMP standard
        
        if let backendURL = URL(string: config.backendURL) {
            backendHost = backendURL.host ?? "localhost"
        } else {
            // Fallback: rimuovi http:// o https://
            backendHost = config.backendURL
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "https://", with: "")
                .components(separatedBy: ":")[0]
                .components(separatedBy: "/")[0]
        }
        
        // Genera RTMP URL (formato: rtmp://host:port/app/stream_name)
        let rtmpURL = "rtmp://\(backendHost):\(rtmpPort)/stream/\(sourceId)"
        
        // Registra sorgente sul backend
        do {
            // Assicurati che UIKit sia importato per UIDevice
            let deviceInfo = DeviceInfo(
                model: UIDevice.modelName,
                osVersion: UIDevice.osVersionString
            )
            
            let response = try await apiClient.registerSource(
                sourceId: sourceId,
                deviceInfo: deviceInfo,
                rtmpUrl: rtmpURL
            )
            
            if response.success {
                // Configura RTMP stream
                rtmpStream.configure(url: rtmpURL, config: config)
                
                // Attendi breve momento per connessione RTMP
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
                
                // Avvia pubblicazione stream
                rtmpStream.start()
                
                // Avvia telemetria
                telemetryService.start(sourceId: sourceId)
                
                isStreaming = true
            } else {
                print("Errore registrazione: \(response.message ?? "unknown")")
            }
        } catch {
            print("Errore avvio streaming: \(error)")
        }
        
        isConnecting = false
    }
    
    func stopStreaming() {
        guard isStreaming else { return }
        
        rtmpStream.stop()
        videoCapture.stop()
        telemetryService.stop()
        
        isStreaming = false
    }
}

