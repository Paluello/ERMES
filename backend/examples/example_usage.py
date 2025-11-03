"""Esempio utilizzo sistema ERMES"""
import asyncio
import time
from app.globals import source_manager
from app.orchestrator import TrackingOrchestrator


async def example_drone():
    """Esempio connessione drone MAVLink"""
    # Registra drone (usa ArduPilot SITL per test)
    # SITL: sim_vehicle.py -v ArduCopter --out=udp:127.0.0.1:14550
    success = source_manager.register_drone(
        source_id="drone_001",
        connection_string="udp:127.0.0.1:14550"
    )
    
    if success:
        print("Drone registrato con successo")
        
        # Attendi connessione
        time.sleep(2)
        
        # Verifica telemetria
        source = source_manager.get_source("drone_001")
        if source:
            telemetry = source.get_latest_telemetry()
            if telemetry:
                print(f"Telemetria drone: lat={telemetry.latitude}, lon={telemetry.longitude}")
    else:
        print("Errore registrazione drone")


async def example_static_camera():
    """Esempio registrazione telecamera fissa"""
    success = source_manager.register_static_camera(
        source_id="camera_piazza_001",
        latitude=41.9028,  # Roma
        longitude=12.4964,
        altitude=50.0,  # metri
        video_url="rtsp://camera.example.com/stream",  # o file://path/to/video.mp4
        camera_tilt=-30.0,  # angolata verso il basso
        camera_pan=90.0,  # orientata a est
        camera_fov_horizontal=84.0,
        camera_fov_vertical=53.0
    )
    
    if success:
        print("Telecamera fissa registrata con successo")
    else:
        print("Errore registrazione telecamera")


async def example_mobile_phone():
    """Esempio registrazione telefono mobile"""
    success = source_manager.register_mobile_phone(
        source_id="phone_001",
        video_url="http://phone.example.com/stream"  # o WebRTC, RTMP, ecc.
    )
    
    if success:
        print("Telefono registrato con successo")
        
        # Simula aggiornamento telemetria dal telefono
        source = source_manager.get_source("phone_001")
        if source:
            source.update_telemetry({
                "latitude": 41.9000,
                "longitude": 12.5000,
                "altitude": 100.0,
                "heading": 45.0,
                "pitch": 0.0,
                "roll": 0.0,
                "yaw": 45.0
            })
            print("Telemetria telefono aggiornata")
    else:
        print("Errore registrazione telefono")


async def example_full_tracking():
    """Esempio completo tracking con orchestratore"""
    orchestrator = TrackingOrchestrator(source_manager)
    orchestrator.start()
    
    # Registra sorgente
    success = source_manager.register_static_camera(
        source_id="test_camera",
        latitude=41.9028,
        longitude=12.4964,
        altitude=50.0,
        video_url="file://path/to/test_video.mp4",  # Video di test
        camera_tilt=-30.0,
        camera_pan=0.0
    )
    
    if success:
        # Avvia elaborazione
        orchestrator.start_processing_source("test_camera")
        print("Tracking avviato per test_camera")
        
        # Attendi qualche secondo
        await asyncio.sleep(10)
        
        # Ferma elaborazione
        orchestrator.stop_processing_source("test_camera")
        print("Tracking fermato")
    
    orchestrator.stop()


if __name__ == "__main__":
    print("Esempi utilizzo ERMES")
    print("=" * 50)
    
    # Scommenta l'esempio che vuoi eseguire:
    
    # asyncio.run(example_drone())
    # asyncio.run(example_static_camera())
    # asyncio.run(example_mobile_phone())
    # asyncio.run(example_full_tracking())

