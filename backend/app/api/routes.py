"""Endpoint REST API"""
from fastapi import APIRouter, HTTPException, Depends
from typing import List, Dict, Any
from app.sources.source_manager import SourceManager
from app.sources.mobile_phone_source import MobilePhoneSource
from app.config import settings
from app.globals import source_manager

router = APIRouter(prefix="/api", tags=["api"])


def get_source_manager() -> SourceManager:
    """Dependency per SourceManager"""
    return source_manager


@router.get("/status")
async def get_status():
    """Ottieni stato sistema"""
    return {
        "status": "running",
        "version": "0.1.0",
        "gps_precision": settings.gps_precision.value,
        "max_tracked_objects": settings.max_tracked_objects
    }


@router.get("/sources")
async def get_sources(manager: SourceManager = Depends(get_source_manager)):
    """Ottieni lista sorgenti registrate"""
    sources = manager.get_all_sources()
    return {
        "sources": [
            {
                "source_id": s.source_id,
                "source_type": s.source_type.value,
                "is_available": s.is_available()
            }
            for s in sources
        ]
    }


@router.get("/telemetry/{source_id}")
async def get_telemetry(
    source_id: str,
    manager: SourceManager = Depends(get_source_manager)
):
    """Ottieni telemetria per sorgente specifica"""
    source = manager.get_source(source_id)
    if not source:
        raise HTTPException(status_code=404, detail=f"Sorgente {source_id} non trovata")
    
    telemetry = source.get_latest_telemetry()
    if not telemetry:
        raise HTTPException(status_code=404, detail=f"Telemetria non disponibile per {source_id}")
    
    return {
        "source_id": telemetry.source_id,
        "source_type": telemetry.source_type.value,
        "timestamp": telemetry.timestamp.isoformat(),
        "latitude": telemetry.latitude,
        "longitude": telemetry.longitude,
        "altitude": telemetry.altitude,
        "heading": telemetry.heading,
        "pitch": telemetry.pitch,
        "roll": telemetry.roll,
        "yaw": telemetry.yaw
    }


@router.post("/sources/mobile/register")
async def register_mobile_source(
    request: dict,
    manager: SourceManager = Depends(get_source_manager)
):
    """Registra un telefono mobile come sorgente video"""
    source_id = request.get("source_id")
    device_info = request.get("device_info", {})
    rtmp_url = request.get("rtmp_url")
    
    if not source_id or not rtmp_url:
        raise HTTPException(
            status_code=400,
            detail="source_id e rtmp_url sono obbligatori"
        )
    
    # Registra sorgente mobile
    success = manager.register_mobile_phone(
        source_id=source_id,
        video_url=rtmp_url
    )
    
    if success:
        return {
            "success": True,
            "source_id": source_id,
            "message": "Sorgente registrata con successo"
        }
    else:
        raise HTTPException(
            status_code=409,
            detail=f"Sorgente {source_id} già registrata"
        )


@router.post("/sources/mobile/{source_id}/telemetry")
async def update_mobile_telemetry(
    source_id: str,
    telemetry_data: dict,
    manager: SourceManager = Depends(get_source_manager)
):
    """Aggiorna telemetria di una sorgente mobile"""
    source = manager.get_source(source_id)
    if not source:
        raise HTTPException(status_code=404, detail=f"Sorgente {source_id} non trovata")
    
    if not isinstance(source, MobilePhoneSource):
        raise HTTPException(
            status_code=400,
            detail=f"Sorgente {source_id} non è una sorgente mobile"
        )
    
    # Aggiorna telemetria
    source.update_telemetry(telemetry_data)
    
    return {
        "success": True,
        "message": "Telemetria aggiornata"
    }


@router.post("/sources/mobile/{source_id}/disconnect")
async def disconnect_mobile_source(
    source_id: str,
    manager: SourceManager = Depends(get_source_manager)
):
    """Disconnette una sorgente mobile"""
    success = manager.remove_source(source_id)
    
    if success:
        return {
            "success": True,
            "message": f"Sorgente {source_id} disconnessa"
        }
    else:
        raise HTTPException(
            status_code=404,
            detail=f"Sorgente {source_id} non trovata"
        )

