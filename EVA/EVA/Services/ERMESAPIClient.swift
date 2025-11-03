//
//  ERMESAPIClient.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation

/// Client per comunicazione con backend ERMES
class ERMESAPIClient {
    private let baseURL: String
    private let apiKey: String?
    private let session: URLSession
    
    init(baseURL: String, apiKey: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config)
    }
    
    /// Registra telefono come sorgente video
    func registerSource(
        sourceId: String,
        deviceInfo: DeviceInfo,
        rtmpUrl: String
    ) async throws -> SourceRegistrationResponse {
        let url = URL(string: "\(baseURL)/api/sources/mobile/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let body = SourceRegistrationRequest(
            sourceId: sourceId,
            deviceInfo: deviceInfo,
            rtmpUrl: rtmpUrl
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(SourceRegistrationResponse.self, from: data)
    }
    
    /// Aggiorna telemetria sorgente
    func updateTelemetry(sourceId: String, telemetry: TelemetryData) async throws {
        let url = URL(string: "\(baseURL)/api/sources/mobile/\(sourceId)/telemetry")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(telemetry)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
    
    /// Disconnette sorgente
    func disconnectSource(sourceId: String) async throws {
        let url = URL(string: "\(baseURL)/api/sources/mobile/\(sourceId)/disconnect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}

enum APIError: Error {
    case invalidResponse
    case httpError(Int)
    case encodingError
    case decodingError
}

