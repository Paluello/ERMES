//
//  StreamConfig.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation

/// Configurazione streaming video
struct StreamConfig {
    var resolution: VideoResolution = .hd1080p
    var frameRate: Int = 30
    var bitrate: Int = 3000000 // 3 Mbps
    var backendURL: String = "http://localhost:8000"
    var apiKey: String?
    
    enum VideoResolution {
        case hd720p  // 1280x720
        case hd1080p // 1920x1080
        case uhd4k   // 3840x2160
        
        var width: Int {
            switch self {
            case .hd720p: return 1280
            case .hd1080p: return 1920
            case .uhd4k: return 3840
            }
        }
        
        var height: Int {
            switch self {
            case .hd720p: return 720
            case .hd1080p: return 1080
            case .uhd4k: return 2160
            }
        }
    }
}

