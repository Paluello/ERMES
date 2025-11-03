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
import RTMPHaishinKit

/// Servizio per streaming RTMP usando HaishinKit
class RTMPStreamService: ObservableObject {
    @Published var isConnected = false
    @Published var streamURL: String?
    @Published var connectionStatus: String = "Disconnesso"
    
    private var rtmpStream: RTMPStream?
    private var rtmpConnection: RTMPConnection?
    private var streamName: String = ""
    private var appName: String = ""
    
    func configure(url: String, config: StreamConfig) async throws {
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
        
        appName = pathComponents[0]
        streamName = pathComponents[1]
        
        // Crea connessione RTMP
        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        
        // Connetti al server RTMP
        // Costruisci URL base per la connessione (host:port/app)
        let connectionURL = "rtmp://\(host):\(port)/\(appName)"
        // Il metodo connect può lanciare errori ed è isolato a un actor
        // Il metodo richiede URL e arguments come parametri separati
        guard let connection = rtmpConnection else {
            throw NSError(domain: "RTMPStreamService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connessione RTMP non inizializzata"])
        }
        _ = try await connection.connect(connectionURL, arguments: nil)
        
        // Monitora lo stato della connessione tramite delegate o property observer
        // Nota: L'API moderna potrebbe usare un approccio diverso per gli eventi
    }
    
    func start() async throws {
        guard let rtmpStream = rtmpStream, !streamName.isEmpty else {
            print("Errore: Stream non configurato correttamente")
            return
        }
        
        // Pubblica stream con il nome dello stream
        // L'app name dovrebbe essere già configurata nella connessione
        // Il metodo publish può lanciare errori ed è isolato a un actor
        // Chiama nel contesto corretto dell'actor
        _ = try await rtmpStream.publish(streamName)
        
        await MainActor.run {
            self.isConnected = true
            self.connectionStatus = "Connesso"
        }
    }
    
    func stop() async throws {
        _ = try await rtmpStream?.close()
        _ = try await rtmpConnection?.close()
        
        await MainActor.run {
            self.isConnected = false
            self.connectionStatus = "Disconnesso"
        }
    }
    
    func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isConnected, rtmpStream != nil else {
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
    
    // TODO: Implementare il monitoraggio dello stato della connessione
    // L'API moderna di HaishinKit potrebbe usare:
    // - Property observers su rtmpConnection.state
    // - Delegate pattern
    // - Combine publishers
    // - O un altro meccanismo per gli eventi
    // Consulta la documentazione di HaishinKit per la versione installata
}

