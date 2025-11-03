//
//  VideoCaptureService.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import AVFoundation
import UIKit
import Combine

/// Servizio per acquisizione video dalla fotocamera
class VideoCaptureService: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "video.capture.queue")
    private var isConfigured = false
    
    @Published var isRunning = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    nonisolated(unsafe) var onFrameCaptured: ((CMSampleBuffer) -> Void)?
    
    private func getOrCreateSession() -> AVCaptureSession {
        if let session = captureSession {
            return session
        }
        let session = AVCaptureSession()
        captureSession = session
        return session
    }
    
    func setup(config: StreamConfig) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Verifica permessi prima di configurare
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            DispatchQueue.main.async {
                self.authorizationStatus = status
            }
            
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.errorMessage = status == .denied || status == .restricted 
                        ? "Permessi camera negati. Vai su Impostazioni > EVA per abilitarli."
                        : "Richiesta permessi camera in corso..."
                }
                return
            }
            
            self.configureSession(config: config)
        }
    }
    
    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("🎬 start() chiamato su sessionQueue")
            
            // Verifica permessi prima di avviare
            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
                print("❌ start(): permessi non concessi")
                DispatchQueue.main.async {
                    self.errorMessage = "Permessi camera non concessi"
                }
                return
            }
            
            guard let session = self.captureSession, self.isConfigured else {
                print("❌ start(): sessione non configurata")
                DispatchQueue.main.async {
                    self.errorMessage = "Camera non configurata. Chiama setup() prima di start()."
                }
                return
            }
            
            if session.isRunning {
                print("ℹ️ start(): sessione già in esecuzione")
                DispatchQueue.main.async {
                    self.isRunning = true
                }
                return
            }
            
            print("🎬 start(): avvio sessione...")
            
            // Su Simulator, la sessione potrebbe non avviarsi correttamente
            // Aggiungiamo gestione speciale
            if UIDevice.isSimulator {
                print("⚠️ Simulator rilevato - la camera potrebbe non funzionare")
            }
            
            // Avvia la sessione in modo sincrono sulla queue dedicata
            // Questo è il modo corretto secondo la documentazione Apple
            // NOTA: Su Simulator, startRunning() potrebbe bloccarsi o non funzionare correttamente
            // ma il preview layer dovrebbe comunque essere visibile
            
            // Imposta subito isRunning a true per permettere alla UI di aggiornarsi
            // Anche se la sessione non si avvia completamente su Simulator
            DispatchQueue.main.async {
                self.isRunning = true
                print("🎬 isRunning impostato a true")
            }
            
            // Avvia la sessione - DEVE essere chiamato sulla sessionQueue
            // Su Simulator potrebbe bloccarsi, ma il preview layer è già stato creato
            // quindi la UI dovrebbe comunque funzionare
            print("🎬 Chiamata startRunning() sulla sessionQueue...")
            session.startRunning()
            print("🎬 startRunning() restituito il controllo")
            
            // Verifica lo stato dopo un breve momento
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let isRunning = session.isRunning
                print("🎬 Stato sessione dopo startRunning(): \(isRunning ? "✅ in esecuzione" : "⚠️ non in esecuzione (normale su Simulator)")")
                
                // Aggiorna lo stato reale
                self.isRunning = isRunning
                
                if !isRunning && !UIDevice.isSimulator {
                    // Su dispositivo fisico, se non è in esecuzione potrebbe essere un problema
                    print("⚠️ La sessione non si è avviata correttamente su dispositivo fisico")
                    self.errorMessage = "Impossibile avviare la camera. Verifica che non sia già in uso da un'altra app."
                }
            }
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let session = self.captureSession else { return }
            
            if session.isRunning {
                session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
    
    private func configureSession(config: StreamConfig) {
        // NOTA: Questo metodo viene già chiamato dentro sessionQueue.async da setup()
        // quindi non serve fare un altro async qui
        
        // Verifica permessi prima di procedere
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            DispatchQueue.main.async {
                self.errorMessage = "Permessi camera non concessi"
            }
            print("⚠️ configureSession: permessi non concessi")
            return
        }
        
        // Crea la sessione solo se non esiste già
        let session = getOrCreateSession()
        
        // Se già configurata, aggiorna solo il preview layer se necessario
        if isConfigured {
            if previewLayer == nil {
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.videoGravity = .resizeAspectFill
                DispatchQueue.main.async {
                    self.previewLayer = preview
                }
            }
            return
        }
        
        print("📷 Configurazione camera in corso...")
        
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Configura la sessione per sopprimere warning su Simulator
        if UIDevice.isSimulator {
            // NOTA: Su iOS Simulator potresti vedere warning di sistema AVFoundation come:
            // - "Fig signalled err=-12710" o "err=-17281"
            // - "FigCaptureSourceRemote Fig assert"
            // Questi sono warning innocui del sistema iOS e vengono ignorati.
            // Non influenzano il funzionamento dell'app e non appaiono su dispositivi fisici.
            session.automaticallyConfiguresApplicationAudioSession = false
        }
        
        // Configura input camera - prova prima la camera posteriore, poi quella anteriore
        var videoDevice: AVCaptureDevice?
        
        // Prova prima la camera posteriore
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            videoDevice = backCamera
        } else if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            videoDevice = frontCamera
            print("⚠️ Camera posteriore non disponibile, uso camera anteriore")
        } else if let anyCamera = AVCaptureDevice.default(for: .video) {
            videoDevice = anyCamera
            print("⚠️ Camera di default non disponibile, uso qualsiasi camera disponibile")
        }
        
        guard let device = videoDevice else {
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.errorMessage = "Camera non disponibile su questo dispositivo"
            }
            print("❌ Nessuna camera disponibile")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            
            // Rimuovi input esistenti prima di aggiungere quello nuovo
            session.inputs.forEach { session.removeInput($0) }
            
            guard session.canAddInput(videoInput) else {
                session.commitConfiguration()
                DispatchQueue.main.async {
                    self.errorMessage = "Impossibile aggiungere input camera"
                }
                print("❌ Impossibile aggiungere input camera")
                return
            }
            
            session.addInput(videoInput)
            print("✅ Input camera aggiunto")
            
            // Configura output video
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: self.sessionQueue)
            
            // Rimuovi output esistenti prima di aggiungere quello nuovo
            session.outputs.forEach { session.removeOutput($0) }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.videoOutput = output
                print("✅ Output video aggiunto")
            } else {
                print("⚠️ Impossibile aggiungere output video")
            }
            
            session.commitConfiguration()
            print("✅ Configurazione sessione completata")
            
            // Marca come configurata
            self.isConfigured = true
            
            // Configura preview layer
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            // Imposta un frame iniziale (verrà aggiornato dalla view)
            preview.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            
            DispatchQueue.main.async {
                self.previewLayer = preview
                self.errorMessage = nil
                print("✅ Preview layer creato e impostato")
                print("📹 Preview layer session: \(preview.session != nil ? "presente" : "nil")")
                print("📹 Preview layer frame iniziale: \(preview.frame)")
                
                // Forza un aggiornamento dopo un breve delay per assicurarsi che la view sia pronta
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Verifica che il preview layer sia ancora impostato
                    if let layer = self.previewLayer {
                        print("📹 Preview layer ancora presente dopo delay")
                        print("📹 Preview layer session running: \(layer.session?.isRunning ?? false)")
                    }
                }
            }
        } catch {
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.errorMessage = "Errore configurazione camera: \(error.localizedDescription)"
            }
            print("❌ Errore configurazione: \(error.localizedDescription)")
        }
    }
    
    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
                if !granted {
                    self.errorMessage = "Permessi camera negati. Vai su Impostazioni > EVA per abilitarli."
                }
            }
            return granted
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.errorMessage = "Permessi camera negati. Vai su Impostazioni > EVA per abilitarli."
            }
            return false
        @unknown default:
            return false
        }
    }
}

extension VideoCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onFrameCaptured?(sampleBuffer)
    }
}

