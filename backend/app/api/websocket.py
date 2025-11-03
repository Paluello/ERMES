"""WebSocket per aggiornamenti real-time"""
from fastapi import WebSocket, WebSocketDisconnect
from typing import List, Dict, Any
import json
import asyncio


class ConnectionManager:
    """Manager connessioni WebSocket"""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        """Accetta nuova connessione"""
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        """Rimuovi connessione"""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
    
    async def broadcast(self, message: Dict[str, Any]):
        """Invia messaggio a tutte le connessioni"""
        message_json = json.dumps(message)
        disconnected = []
        
        for connection in self.active_connections:
            try:
                await connection.send_text(message_json)
            except Exception as e:
                print(f"Errore invio WebSocket: {e}")
                disconnected.append(connection)
        
        # Rimuovi connessioni disconnesse
        for conn in disconnected:
            self.disconnect(conn)


connection_manager = ConnectionManager()


async def websocket_endpoint(websocket: WebSocket):
    """Endpoint WebSocket principale"""
    await connection_manager.connect(websocket)
    try:
        while True:
            # Mantieni connessione viva
            data = await websocket.receive_text()
            # Echo per keepalive (opzionale)
            await websocket.send_text(json.dumps({"type": "pong"}))
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket)

