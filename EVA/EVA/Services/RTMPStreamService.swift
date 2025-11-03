//
//  RTMPStreamService.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import AVFoundation
import VideoToolbox
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
        
        // TODO: Configurare videoSettings e audioSettings secondo l'API di HaishinKit
        // L'API esatta dipende dalla versione di HaishinKit installata
        // Potrebbe essere necessario usare VideoCodecSettings() e AudioCodecSettings()
        // oppure configurare tramite altre proprietà di RTMPStream
        // Consulta la documentazione di HaishinKit per la versione installata
        
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
        rtmpStream?.close()
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
        
        // TODO: Implementare l'invio del frame video a RTMPStream
        // L'API di HaishinKit potrebbe usare:
        // - rtmpStream.attachVideo() con AVCaptureVideoDataOutput
        // - rtmpStream.append() con CMSampleBuffer
        // - o un altro metodo specifico della versione di HaishinKit
        // Consulta la documentazione di HaishinKit per la versione installata
        // Per ora lasciamo vuoto - da implementare secondo l'API corretta
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        
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

