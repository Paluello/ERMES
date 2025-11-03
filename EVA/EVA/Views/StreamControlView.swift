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
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Preview video a tutto schermo (sotto)
            if let previewLayer = streamManager.videoCapture.previewLayer {
                VideoPreviewView(previewLayer: previewLayer)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Caricamento camera...")
                                .foregroundColor(.white)
                                .padding(.top)
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
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Aggiorna il frame quando la view cambia dimensione
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = uiView.bounds
        CATransaction.commit()
    }
}

