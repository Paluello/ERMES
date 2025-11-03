//
//  Extensions.swift
//  EVA
//
//  Created for ERMES Video Analyst
//

import Foundation
import UIKit

extension UIDevice {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    static var osVersionString: String {
        return UIDevice.current.systemVersion
    }
}

extension UUID {
    static var deviceUUID: UUID {
        // Usa UserDefaults per mantenere lo stesso UUID tra sessioni
        let key = "EVA_DeviceUUID"
        if let uuidString = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: uuidString) {
            return uuid
        }
        let newUUID = UUID()
        UserDefaults.standard.set(newUUID.uuidString, forKey: key)
        return newUUID
    }
}

