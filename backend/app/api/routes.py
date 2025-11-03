"""Endpoint REST API"""
from fastapi import APIRouter, HTTPException, Depends, Request, Header
from typing import List, Dict, Any, Optional
import hmac
import hashlib
import subprocess
import os
from app.sources.source_manager import SourceManager
from app.sources.mobile_phone_source import MobilePhoneSource
from app.config import settings
from app.globals import source_manager, get_orchestrator

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
        # Avvia elaborazione video per la sorgente appena registrata
        orchestrator = get_orchestrator()
        if orchestrator:
            try:
                orchestrator.start_processing_source(source_id)
                print(f"Elaborazione video avviata per sorgente mobile {source_id}")
            except Exception as e:
                print(f"Attenzione: impossibile avviare elaborazione per {source_id}: {e}")
                # Non falliamo la registrazione se l'elaborazione non parte
        
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


@router.post("/update/trigger")
async def trigger_update():
    """
    Endpoint per triggerare manualmente l'aggiornamento del sistema da GitHub.
    
    Questo endpoint esegue lo stesso processo di aggiornamento del webhook GitHub,
    ma può essere chiamato manualmente dall'interfaccia Swagger.
    
    ⚠️ ATTENZIONE: Questo processo può richiedere alcuni minuti.
    """
    try:
        # Trova lo script di aggiornamento
        update_script = os.getenv("UPDATE_SCRIPT_PATH", "/app/update_container.sh")
        
        if not os.path.exists(update_script):
            raise HTTPException(
                status_code=500,
                detail=f"Script di aggiornamento non trovato: {update_script}"
            )
        
        # Esegui aggiornamento in background
        process = subprocess.Popen(
            ["/bin/bash", update_script],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        return {
            "success": True,
            "message": "Aggiornamento avviato in background",
            "process_id": process.pid,
            "note": "Controlla i log con: docker logs ermes-backend | grep update"
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Errore durante avvio aggiornamento: {str(e)}"
        )


@router.get("/update/status")
async def get_update_status():
    """
    Ottieni lo stato dell'ultimo aggiornamento controllando i log.
    """
    log_file = "/tmp/ermes_update.log"
    
    if not os.path.exists(log_file):
        return {
            "status": "no_logs",
            "message": "Nessun log di aggiornamento trovato"
        }
    
    try:
        with open(log_file, 'r') as f:
            lines = f.readlines()
            last_lines = lines[-10:] if len(lines) > 10 else lines
        
        return {
            "status": "available",
            "last_logs": "".join(last_lines),
            "total_lines": len(lines)
        }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Errore lettura log: {str(e)}"
        }


@router.post("/webhook/github")
async def github_webhook(
    request: Request,
    x_github_event: Optional[str] = Header(None),
    x_hub_signature_256: Optional[str] = Header(None)
):
    """
    Webhook endpoint per GitHub - aggiorna automaticamente il container quando c'è un push
    
    Configurazione GitHub:
    1. Vai su Settings > Webhooks > Add webhook
    2. Payload URL: http://tuo-nas-ip:8000/api/webhook/github
    3. Content type: application/json
    4. Secret: (opzionale, ma consigliato) imposta GITHUB_WEBHOOK_SECRET nel .env
    5. Events: seleziona "Just the push event"
    """
    if not settings.github_webhook_enabled:
        raise HTTPException(
            status_code=403,
            detail="Webhook GitHub non abilitato. Imposta GITHUB_WEBHOOK_ENABLED=true nel .env"
        )
    
    # Verifica che sia un evento GitHub valido
    if x_github_event != "push":
        return {"message": "Ignorato - non è un evento push", "event": x_github_event}
    
    # Verifica signature se secret è configurato
    if settings.github_webhook_secret:
        if not x_hub_signature_256:
            raise HTTPException(status_code=401, detail="Signature mancante")
        
        body = await request.body()
        expected_signature = "sha256=" + hmac.new(
            settings.github_webhook_secret.encode(),
            body,
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(x_hub_signature_256, expected_signature):
            raise HTTPException(status_code=401, detail="Signature non valida")
    
    # Leggi payload
    payload = await request.json()
    
    # Verifica che sia un push sul branch corretto (se configurato)
    ref = payload.get("ref", "")
    if ref and not ref.endswith("/main") and not ref.endswith("/master"):
        return {
            "message": "Ignorato - push su branch diverso da main/master",
            "ref": ref
        }
    
    # Esegui aggiornamento in background
    try:
        # Trova lo script di aggiornamento (nel container o sul host)
        update_script = os.getenv("UPDATE_SCRIPT_PATH", "/app/update_container.sh")
        
        # Se lo script esiste, eseguilo
        if os.path.exists(update_script):
            subprocess.Popen(
                ["/bin/bash", update_script],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            return {
                "success": True,
                "message": "Aggiornamento avviato",
                "commit": payload.get("head_commit", {}).get("id", "unknown")[:7]
            }
        else:
            # Fallback: ritorna info ma non esegue aggiornamento
            return {
                "success": False,
                "message": "Script di aggiornamento non trovato",
                "expected_path": update_script,
                "commit": payload.get("head_commit", {}).get("id", "unknown")[:7]
            }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Errore durante avvio aggiornamento: {str(e)}"
        )

