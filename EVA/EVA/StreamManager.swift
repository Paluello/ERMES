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
    var telemetryService: TelemetryService
    
    private var apiClient: ERMESAPIClient
    private let sourceId: String
    
    init() {
        // Genera UUID device per source_id
        sourceId = UUID.deviceUUID.uuidString
        
        // Inizializza API client con configurazione di default
        apiClient = ERMESAPIClient(baseURL: config.backendURL, apiKey: config.apiKey)
        
        // Inizializza telemetry service
        telemetryService = TelemetryService(apiClient: apiClient)
        
        // Setup video capture callback
        videoCapture.onFrameCaptured = { [weak self] sampleBuffer in
            self?.rtmpStream.appendVideoSampleBuffer(sampleBuffer)
        }
        
        // Configura e avvia la camera immediatamente per la preview
        setupCameraPreview()
    }
    
    private func setupCameraPreview() {
        // Richiedi permessi e avvia camera per preview
        Task { @MainActor in
            print("📷 Richiesta permessi camera...")
            // Richiedi permessi usando il metodo del servizio
            let granted = await videoCapture.requestPermission()
            
            if granted {
                print("✅ Permessi camera concessi")
                
                // Piccolo delay per assicurarsi che i permessi siano completamente processati
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 secondi
                
                // Verifica di nuovo lo stato dopo il delay
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                guard status == .authorized else {
                    print("⚠️ Permessi camera non ancora disponibili dopo la richiesta")
                    return
                }
                
                print("📷 Configurazione camera...")
                // Configura e avvia camera per preview (anche senza streaming)
                videoCapture.setup(config: config)
                
                // Attendi che la configurazione sia completata (il setup è asincrono)
                // Aspettiamo un po' di più per permettere la configurazione completa
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
                
                print("📷 Avvio camera...")
                videoCapture.start()
                
                // Attendi che la sessione si avvii
                // Su Simulator potrebbe non funzionare, ma il preview layer dovrebbe comunque essere visibile
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
                
                // Verifica che il preview layer sia stato creato
                if videoCapture.previewLayer == nil {
                    print("⚠️ Preview layer non creato dopo il primo tentativo")
                    // Riprova la configurazione
                    print("🔄 Riprovo configurazione...")
                    videoCapture.setup(config: config)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    videoCapture.start()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                
                // Verifica finale
                if videoCapture.previewLayer != nil {
                    print("✅ Preview layer disponibile!")
                } else {
                    print("❌ Preview layer ancora non disponibile")
                    if UIDevice.isSimulator {
                        print("ℹ️ Su Simulator la camera potrebbe non funzionare correttamente")
                    }
                }
            } else {
                print("⚠️ Permessi camera negati. L'utente deve abilitarli nelle Impostazioni.")
            }
        }
    }
    
    func startStreaming() async {
        guard !isStreaming && !isConnecting else { return }
        
        isConnecting = true
        
        // Richiedi permessi camera
        let granted = await videoCapture.requestPermission()
        
        guard granted else {
            print("⚠️ Impossibile avviare streaming: permessi camera negati")
            isConnecting = false
            return
        }
        
        // Aggiorna API client con configurazione corrente (nel caso sia cambiata)
        apiClient = ERMESAPIClient(baseURL: config.backendURL, apiKey: config.apiKey)
        telemetryService = TelemetryService(apiClient: apiClient)
        
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
            
            var response: SourceRegistrationResponse
            
            // Prova a registrare la sorgente
            do {
                response = try await apiClient.registerSource(
                    sourceId: sourceId,
                    deviceInfo: deviceInfo,
                    rtmpUrl: rtmpURL
                )
            } catch let error as APIError {
                // Se la sorgente è già registrata (409), disconnetti e riprova
                if case .httpError(let statusCode) = error, statusCode == 409 {
                    print("⚠️ Sorgente già registrata. Disconnessione e nuovo tentativo...")
                    do {
                        // Prova a disconnettere la sorgente esistente
                        try await apiClient.disconnectSource(sourceId: sourceId)
                        // Attendi un momento prima di riprovare
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
                        // Riprova la registrazione
                        response = try await apiClient.registerSource(
                            sourceId: sourceId,
                            deviceInfo: deviceInfo,
                            rtmpUrl: rtmpURL
                        )
                        print("✅ Sorgente riconnessa con successo")
                    } catch {
                        // Se anche la disconnessione fallisce, rilancia l'errore originale
                        print("⚠️ Impossibile disconnettere sorgente esistente: \(error)")
                        throw error
                    }
                } else {
                    // Per altri errori, rilancia direttamente
                    throw error
                }
            }
            
            if response.success {
                // Configura RTMP stream (async)
                try await rtmpStream.configure(url: rtmpURL, config: config)
                
                // Attendi breve momento per connessione RTMP
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondi
                
                // Avvia pubblicazione stream (async)
                try await rtmpStream.start()
                
                // Avvia telemetria
                telemetryService.start(sourceId: sourceId)
                
                isStreaming = true
            } else {
                print("Errore registrazione: \(response.message ?? "unknown")")
            }
        } catch let error as APIError {
            print("Errore avvio streaming: \(error)")
            // Gestisci errori API specifici
            switch error {
            case .httpError(let statusCode):
                print("⚠️ Errore HTTP \(statusCode)")
            case .invalidResponse:
                print("⚠️ Risposta non valida dal backend")
            case .encodingError, .decodingError:
                print("⚠️ Errore di codifica/decodifica dati")
            }
        } catch {
            print("Errore avvio streaming: \(error)")
            // Mostra errore più dettagliato
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotConnectToHost, .networkConnectionLost:
                    print("⚠️ Impossibile connettersi al backend. Verifica che:")
                    print("   1. Il backend ERMES sia in esecuzione")
                    print("   2. L'URL backend sia corretto nelle impostazioni")
                    print("   3. Se usi un dispositivo fisico, usa l'IP del Mac invece di 'localhost'")
                default:
                    print("⚠️ Errore di connessione: \(urlError.localizedDescription)")
                }
            } else {
                print("⚠️ Errore: \(error.localizedDescription)")
            }
        }
        
        isConnecting = false
    }
    
    func stopStreaming() async {
        guard isStreaming else { return }
        
        do {
            try await rtmpStream.stop()
        } catch {
            print("Errore stop streaming: \(error)")
        }
        
        videoCapture.stop()
        telemetryService.stop()
        
        isStreaming = false
    }
}

