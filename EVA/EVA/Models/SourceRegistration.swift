//
//  SourceRegistration.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation

/// Request per registrazione sorgente mobile
struct SourceRegistrationRequest: Codable {
    let sourceId: String
    let deviceInfo: DeviceInfo
    let rtmpUrl: String
    
    enum CodingKeys: String, CodingKey {
        case sourceId = "source_id"
        case deviceInfo = "device_info"
        case rtmpUrl = "rtmp_url"
    }
}

struct DeviceInfo: Codable {
    let model: String
    let osVersion: String
    
    enum CodingKeys: String, CodingKey {
        case model
        case osVersion = "os_version"
    }
}

/// Response registrazione sorgente
struct SourceRegistrationResponse: Codable {
    let success: Bool
    let sourceId: String?
    let message: String?
}

