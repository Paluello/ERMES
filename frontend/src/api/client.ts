/** Client API e WebSocket per comunicazione backend */

const API_BASE_URL = '/api';
const WS_URL = `ws://${window.location.host}/ws`;

export interface TelemetryData {
    source_id: string;
    source_type: string;
    timestamp: string;
    latitude: number;
    longitude: number;
    altitude: number;
    heading?: number;
    pitch?: number;
    roll?: number;
    yaw?: number;
}

export interface Detection {
    track_id: number;
    class_name: string;
    latitude: number;
    longitude: number;
    confidence: number;
    source_id: string;
    source_type: string;
    accuracy_meters?: number;
}

export interface Source {
    source_id: string;
    source_type: string;
    is_available: boolean;
}

export class APIClient {
    static async getStatus(): Promise<any> {
        const response = await fetch(`${API_BASE_URL}/status`);
        return response.json();
    }

    static async getSources(): Promise<Source[]> {
        const response = await fetch(`${API_BASE_URL}/sources`);
        const data = await response.json();
        return data.sources;
    }

    static async getTelemetry(sourceId: string): Promise<TelemetryData> {
        const response = await fetch(`${API_BASE_URL}/telemetry/${sourceId}`);
        return response.json();
    }
}

export class WebSocketClient {
    private ws: WebSocket | null = null;
    private reconnectInterval: number = 3000;
    private onDetectionCallback?: (detection: Detection) => void;
    private onTelemetryCallback?: (telemetry: TelemetryData) => void;

    connect(): void {
        try {
            this.ws = new WebSocket(WS_URL);
            
            this.ws.onopen = () => {
                console.log('WebSocket connesso');
                this.onConnectionChange?.(true);
            };

            this.ws.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    console.log('Messaggio WebSocket ricevuto:', data);
                    this.handleMessage(data);
                } catch (e) {
                    console.error('Errore parsing messaggio WebSocket:', e, event.data);
                }
            };

            this.ws.onerror = (error) => {
                console.error('Errore WebSocket:', error);
            };

            this.ws.onclose = () => {
                console.log('WebSocket disconnesso');
                this.onConnectionChange?.(false);
                // Riconnessione automatica
                setTimeout(() => this.connect(), this.reconnectInterval);
            };
        } catch (e) {
            console.error('Errore connessione WebSocket:', e);
            setTimeout(() => this.connect(), this.reconnectInterval);
        }
    }

    disconnect(): void {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }

    onDetection(callback: (detection: Detection) => void): void {
        this.onDetectionCallback = callback;
    }

    onTelemetry(callback: (telemetry: TelemetryData) => void): void {
        this.onTelemetryCallback = callback;
    }

    private onConnectionChange?: (connected: boolean) => void;
    setConnectionChangeCallback(callback: (connected: boolean) => void): void {
        this.onConnectionChange = callback;
    }

    private handleMessage(data: any): void {
        console.log('Gestione messaggio WebSocket:', data.type);
        
        if (data.type === 'detection' && this.onDetectionCallback) {
            console.log('Chiamata callback detection con payload:', data.payload);
            this.onDetectionCallback(data.payload);
        } else if (data.type === 'telemetry' && this.onTelemetryCallback) {
            console.log('Chiamata callback telemetry con payload:', data.payload);
            this.onTelemetryCallback(data.payload);
        } else if (data.type === 'pong') {
            // Messaggio keepalive, ignoriamo
            console.log('WebSocket keepalive ricevuto');
        } else {
            console.warn('Tipo messaggio WebSocket sconosciuto o callback non impostato:', data.type);
        }
    }

    isConnected(): boolean {
        return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
    }
}

