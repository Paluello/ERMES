//
//  TelemetryDisplayView.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import SwiftUI

struct TelemetryDisplayView: View {
    let telemetry: TelemetryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Telemetria")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Lat")
                    Text("Lon")
                    Text("Alt")
                }
                .font(.caption)
                
                VStack(alignment: .leading) {
                    Text(String(format: "%.6f", telemetry.latitude))
                    Text(String(format: "%.6f", telemetry.longitude))
                    Text(String(format: "%.1f m", telemetry.altitude))
                }
                .font(.caption.monospaced())
                
                Spacer()
                
                if let heading = telemetry.heading {
                    VStack {
                        Text("Heading")
                            .font(.caption)
                        Text(String(format: "%.0f°", heading))
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

