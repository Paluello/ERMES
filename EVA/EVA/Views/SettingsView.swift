//
//  SettingsView.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var streamManager: StreamManager
    @Environment(\.dismiss) var dismiss
    
    @State private var backendURL: String
    @State private var apiKey: String
    @State private var selectedResolution: StreamConfig.VideoResolution
    
    init(streamManager: StreamManager) {
        self.streamManager = streamManager
        _backendURL = State(initialValue: streamManager.config.backendURL)
        _apiKey = State(initialValue: streamManager.config.apiKey ?? "")
        _selectedResolution = State(initialValue: streamManager.config.resolution)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Backend ERMES") {
                    TextField("URL Backend", text: $backendURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    SecureField("API Key (opzionale)", text: $apiKey)
                        .autocapitalization(.none)
                }
                
                Section("Video") {
                    Picker("Risoluzione", selection: $selectedResolution) {
                        Text("720p HD").tag(StreamConfig.VideoResolution.hd720p)
                        Text("1080p Full HD").tag(StreamConfig.VideoResolution.hd1080p)
                        Text("4K UHD").tag(StreamConfig.VideoResolution.uhd4k)
                    }
                }
                
                Section {
                    Button("Salva") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        streamManager.config.backendURL = backendURL
        streamManager.config.apiKey = apiKey.isEmpty ? nil : apiKey
        streamManager.config.resolution = selectedResolution
    }
}

