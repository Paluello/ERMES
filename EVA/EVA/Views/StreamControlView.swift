//
//  StreamControlView.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import SwiftUI
import AVFoundation

struct StreamControlView: View {
    @ObservedObject var streamManager: StreamManager
    @ObservedObject private var videoCapture: VideoCaptureService
    @State private var showingSettings = false
    
    init(streamManager: StreamManager) {
        self.streamManager = streamManager
        self.videoCapture = streamManager.videoCapture
    }
    
    var body: some View {
        ZStack {
            // Preview video a tutto schermo (sotto)
            if let previewLayer = videoCapture.previewLayer {
                ZStack {
                    VideoPreviewView(previewLayer: previewLayer)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: streamManager.isStreaming ? 0 : 15) // Sfocato quando non in streaming
                        .animation(.easeInOut(duration: 0.3), value: streamManager.isStreaming)
                    
                    // Su Simulator, mostra un messaggio informativo
                    if UIDevice.isSimulator {
                        VStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.7))
                                Text("iOS Simulator")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                Text("La camera non è disponibile su Simulator.\nProva su un dispositivo fisico per vedere il video.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                            .padding(.bottom, 100)
                        }
                    }
                }
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            if let errorMessage = videoCapture.errorMessage {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.orange)
                                    
                                    Text("Errore Camera")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(errorMessage)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    if videoCapture.authorizationStatus == .denied || 
                                       videoCapture.authorizationStatus == .restricted {
                                        Button(action: {
                                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(settingsUrl)
                                            }
                                        }) {
                                            Text("Apri Impostazioni")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(Color.blue)
                                                .cornerRadius(10)
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Caricamento camera...")
                                        .foregroundColor(.white)
                                        .padding(.top)
                                }
                            }
                        }
                    )
            }
            
            // Controlli sovrapposti in basso
            VStack {
                Spacer()
                VStack(spacing: 16) {
                // Stato connessione
                HStack {
                    Circle()
                        .fill(streamManager.isStreaming ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(streamManager.isStreaming ? "Streaming attivo" : "Non in streaming")
                        .font(.caption)
                }
                
                // Pulsante Start/Stop
                Button(action: {
                    if streamManager.isStreaming {
                        Task {
                            await streamManager.stopStreaming()
                        }
                    } else {
                        Task {
                            await streamManager.startStreaming()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: streamManager.isStreaming ? "stop.circle.fill" : "play.circle.fill")
                        Text(streamManager.isStreaming ? "Stop Streaming" : "Start Streaming")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(streamManager.isStreaming ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(streamManager.isConnecting)
                
                // Telemetria display
                if let telemetry = streamManager.telemetryService.lastTelemetry {
                    TelemetryDisplayView(telemetry: telemetry)
                }
                }
                .padding()
                .background(
                    Color.black.opacity(0.7)
                        .background(.ultraThinMaterial)
                )
                .cornerRadius(16)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("ERMES Streamer")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(streamManager: streamManager)
        }
    }
}

struct VideoPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Assicurati che il preview layer sia aggiunto correttamente
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        print("📹 VideoPreviewView creata, frame: \(view.bounds)")
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Aggiorna il frame quando la view cambia dimensione
        // IMPORTANTE: aggiorna sempre il frame perché potrebbe cambiare
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let newFrame = uiView.bounds
            if previewLayer.frame != newFrame {
                previewLayer.frame = newFrame
                print("📹 Preview layer frame aggiornato: \(newFrame)")
            }
            CATransaction.commit()
            
            // Assicurati che il preview layer sia ancora nella view
            if previewLayer.superlayer != uiView.layer {
                print("⚠️ Preview layer non nella view, riaggiungo...")
                previewLayer.removeFromSuperlayer()
                uiView.layer.addSublayer(previewLayer)
            }
        }
    }
}

