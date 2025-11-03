//
//  RTMPStreamService.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import AVFoundation
import Combine
import HaishinKit

/// Servizio per streaming RTMP usando HaishinKit
class RTMPStreamService: ObservableObject {
    @Published var isConnected = false
    @Published var streamURL: String?
    @Published var connectionStatus: String = "Disconnesso"
    
    private var rtmpStream: RTMPStream?
    private var rtmpConnection: RTMPConnection?
    private var streamName: String = ""
    
    func configure(url: String, config: StreamConfig) {
        self.streamURL = url
        
        // Parse URL RTMP (formato: rtmp://host:port/app/stream_name)
        guard let urlComponents = URL(string: url) else {
            print("Errore: URL RTMP non valido")
            return
        }
        
        let host = urlComponents.host ?? "localhost"
        let port = urlComponents.port ?? 1935
        let pathComponents = urlComponents.path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard pathComponents.count >= 2 else {
            print("Errore: URL RTMP deve essere nel formato rtmp://host:port/app/stream_name")
            return
        }
        
        let appName = pathComponents[0]
        streamName = pathComponents[1]
        
        // Crea connessione RTMP
        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        
        // Configurazione video
        rtmpStream?.videoSettings = [
            .width: config.resolution.width,
            .height: config.resolution.height,
            .bitrate: config.bitrate,
            .profileLevel: kVTProfileLevel_H264_Baseline_AutoLevel,
            .maxKeyFrameIntervalDuration: 2.0
        ]
        
        // Configurazione audio (opzionale, per ora disabilitato)
        rtmpStream?.audioSettings = [
            .muted: true
        ]
        
        // Setup delegate per monitorare stato connessione
        rtmpConnection?.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        
        // Connetti al server RTMP
        rtmpConnection?.connect("\(host):\(port)/\(appName)")
    }
    
    func start() {
        guard let rtmpStream = rtmpStream, !streamName.isEmpty else {
            print("Errore: Stream non configurato correttamente")
            return
        }
        
        // Pubblica stream
        rtmpStream.publish(streamName)
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "Connesso"
        }
    }
    
    func stop() {
        rtmpStream?.stopPublish()
        rtmpConnection?.close()
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnesso"
        }
    }
    
    func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isConnected, let rtmpStream = rtmpStream else {
            return
        }
        
        // Invia frame video allo stream RTMP
        rtmpStream.appendSampleBuffer(sampleBuffer, withType: .video)
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        guard let e = Event.from(notification) else { return }
        
        let data = e.data as? ASObject
        guard let code = data?["code"] as? String else { return }
        
        DispatchQueue.main.async {
            switch code {
            case RTMPConnection.Code.connectSuccess.rawValue:
                self.connectionStatus = "Connesso"
                self.isConnected = true
            case RTMPConnection.Code.connectFailed.rawValue,
                 RTMPConnection.Code.connectClosed.rawValue:
                self.connectionStatus = "Disconnesso"
                self.isConnected = false
            default:
                self.connectionStatus = code
            }
        }
    }
}

