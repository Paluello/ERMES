# EVA - Ermes Video Analyst

App iOS nativa in Swift per trasformare iPhone in sorgente video mobile per il sistema ERMES.

## Stato Implementazione

### ✅ Completato

- **Struttura progetto**: Modelli, Servizi, Views, Utils
- **TelemetryService**: Acquisizione GPS (CoreLocation) e IMU (CoreMotion)
- **ERMESAPIClient**: Client REST API per comunicazione backend
- **VideoCaptureService**: Acquisizione video dalla fotocamera (AVFoundation)
- **UI SwiftUI**: Interfaccia principale con preview video e controlli
- **Backend API**: Endpoint per registrazione/disconnessione sorgenti mobile

### ⚠️ Da Completare

- **RTMPStreamService**: Integrazione HaishinKit per streaming RTMP
- **Configurazione Info.plist**: Aggiungere permessi al progetto Xcode
- **Dipendenze**: Aggiungere HaishinKit via Swift Package Manager o CocoaPods
- **Server RTMP Backend**: Configurare server RTMP per ricevere stream

## Setup Progetto

### 1. Aggiungere Dipendenze

**Opzione A: Swift Package Manager (Raccomandato)**

1. Apri Xcode
2. File → Add Package Dependencies
3. Aggiungi: `https://github.com/shogo4405/HaishinKit.swift`
4. Versione: 1.5.0 o superiore

**Opzione B: CocoaPods**

```bash
cd EVA
pod init
```

Aggiungi al `Podfile`:
```ruby
platform :ios, '16.0'
target 'EVA' do
  use_frameworks!
  pod 'HaishinKit', '~> 1.5'
end
```

Poi:
```bash
pod install
```

### 2. Configurare Info.plist

Nel progetto Xcode, aggiungi le seguenti chiavi a Info.plist:

- `NSCameraUsageDescription`: "L'app necessita accesso alla fotocamera per trasmettere video live al sistema ERMES"
- `NSLocationWhenInUseUsageDescription`: "L'app necessita la posizione GPS per geolocalizzare oggetti rilevati nel video"
- `NSLocationAlwaysAndWhenInUseUsageDescription`: "Posizione sempre attiva per tracking continuo degli oggetti"
- `NSMotionUsageDescription`: "L'app usa sensori movimento per calcolare l'orientamento del telefono e geolocalizzare con precisione gli oggetti"

### 3. Implementare RTMPStreamService

Il file `RTMPStreamService.swift` è attualmente un placeholder. Dopo aver aggiunto HaishinKit, implementare:

```swift
import HaishinKit

class RTMPStreamService: ObservableObject {
    private var rtmpStream: RTMPStream?
    private var rtmpConnection: RTMPConnection?
    
    func configure(url: String, config: StreamConfig) {
        rtmpConnection = RTMPConnection()
        rtmpStream = RTMPStream(connection: rtmpConnection!)
        
        // Configurazione stream
        rtmpStream?.videoSettings = [
            .width: config.resolution.width,
            .height: config.resolution.height,
            .bitrate: config.bitrate
        ]
        
        rtmpConnection?.connect(url)
    }
    
    func start() {
        rtmpStream?.publish("stream")
        isConnected = true
    }
    
    func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        rtmpStream?.appendSampleBuffer(sampleBuffer, withType: .video)
    }
}
```

## Configurazione Backend

### Server RTMP

Il backend ERMES deve essere configurato per ricevere stream RTMP. Opzioni:

1. **nginx-rtmp** (Raccomandato per semplicità)
2. **SRS** (Simple Realtime Server)
3. **Integrazione Python** con aiortc/pyav

### Endpoint API Backend

Gli endpoint seguenti sono già implementati:

- `POST /api/sources/mobile/register` - Registra telefono
- `POST /api/sources/mobile/{source_id}/telemetry` - Aggiorna telemetria
- `POST /api/sources/mobile/{source_id}/disconnect` - Disconnette sorgente

## Utilizzo

1. **Configurazione Backend**: Imposta URL backend nelle impostazioni app
2. **Avvia Streaming**: Tocca "Start Streaming"
3. **Permessi**: L'app richiederà permessi camera, location e motion
4. **Telemetria**: La telemetria viene inviata automaticamente a 10 Hz
5. **Stop**: Tocca "Stop Streaming" per fermare trasmissione

## Architettura

```
EVA/
├── Models/              # Data models
├── Services/            # Business logic
│   ├── ERMESAPIClient  # REST API client
│   ├── TelemetryService # GPS/IMU acquisition
│   ├── VideoCaptureService # Camera capture
│   └── RTMPStreamService # RTMP streaming
├── Views/               # SwiftUI views
└── Utils/              # Utilities (Location, Motion wrappers)
```

## Note Implementazione

- **UUID Device**: L'app genera un UUID univoco persistente per identificare il device
- **Telemetria 10Hz**: Aggiornamento GPS/IMU ogni 100ms
- **Async/Await**: Tutte le chiamate API usano async/await (Swift 5.5+)
- **Background Mode**: Supporto futuro per continuare telemetria in background

## Troubleshooting

### Errore compilazione Swift
- Verifica che tutti i file siano inclusi nel target EVA
- Controlla che le dipendenze siano correttamente aggiunte

### Permessi non richiesti
- Verifica Info.plist contiene tutte le chiavi necessarie
- Reset permessi app nelle impostazioni iOS

### Connessione backend fallita
- Verifica URL backend nelle impostazioni
- Controlla che backend sia in esecuzione
- Verifica firewall/network

## Prossimi Passi

1. Completare integrazione HaishinKit
2. Configurare server RTMP backend
3. Test end-to-end streaming
4. Implementare background mode
5. Ottimizzazione batteria e performance

