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
    # Prova a ottenere il commit Git corrente
    git_commit = None
    git_branch = None
    try:
        # Verifica se siamo in una repo git
        repo_path = os.getenv("GITHUB_REPO_PATH", "/volume1/docker/ERMES")
        if os.path.exists(os.path.join(repo_path, ".git")):
            result = subprocess.run(
                ["git", "-C", repo_path, "rev-parse", "HEAD"],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result.returncode == 0:
                git_commit = result.stdout.strip()[:7]  # Primi 7 caratteri
            
            result_branch = subprocess.run(
                ["git", "-C", repo_path, "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result_branch.returncode == 0:
                git_branch = result_branch.stdout.strip()
    except Exception:
        pass  # Ignora errori git
    
    return {
        "status": "running",
        "version": "0.1.0",
        "git_commit": git_commit,
        "git_branch": git_branch,
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


@router.get("/update/polling/status")
async def get_polling_status():
    """
    Ottieni lo stato del polling automatico (se abilitato).
    """
    from app.globals import get_auto_updater
    
    auto_updater = get_auto_updater()
    
    if not auto_updater:
        return {
            "enabled": False,
            "message": "Polling automatico non abilitato. Configura GITHUB_AUTO_UPDATE_ENABLED=true nel .env"
        }
    
    return {
        "enabled": True,
        "is_running": auto_updater.is_running,
        "repository": auto_updater.github_repo,
        "branch": auto_updater.github_branch,
        "poll_interval_minutes": auto_updater.poll_interval_seconds // 60,
        "last_commit_sha": auto_updater.last_commit_sha[:7] if auto_updater.last_commit_sha else None
    }


@router.post("/update/polling/check")
async def force_polling_check():
    """
    Forza un controllo immediato per nuovi commit (utile per test).
    """
    from app.globals import get_auto_updater
    
    auto_updater = get_auto_updater()
    
    if not auto_updater:
        raise HTTPException(
            status_code=400,
            detail="Polling automatico non abilitato"
        )
    
    try:
        updated = await auto_updater.force_check()
        return {
            "success": True,
            "updated": updated,
            "message": "Aggiornamento avviato" if updated else "Nessun nuovo commit trovato",
            "last_commit_sha": auto_updater.last_commit_sha[:7] if auto_updater.last_commit_sha else None
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Errore durante controllo: {str(e)}"
        )


@router.post("/rtmp/on_publish")
async def rtmp_on_publish(request: Request):
    """
    Callback chiamato da nginx-rtmp quando uno stream inizia la pubblicazione.
    Questo endpoint viene chiamato automaticamente da nginx quando riceve un nuovo stream RTMP.
    """
    try:
        # nginx-rtmp invia i parametri come form data
        form_data = await request.form()
        
        # Estrai parametri comuni da nginx-rtmp
        app = form_data.get("app", "unknown")
        name = form_data.get("name", "unknown")  # Questo è il source_id
        addr = form_data.get("addr", "unknown")
        
        # Il name dovrebbe essere il source_id (es. "90BCE65A-589D-4C87-8420-ABF974A86E85")
        source_id = name
        
        print(f"📹 RTMP PUBLISH START: source_id={source_id}, app={app}, addr={addr}")
        
        # Verifica se la sorgente è registrata
        source = source_manager.get_source(source_id)
        if source:
            print(f"✅ Sorgente {source_id} trovata nel manager")
        else:
            print(f"⚠️ Sorgente {source_id} NON trovata nel manager - potrebbe essere una connessione orfana")
        
        # Ritorna 200 OK per accettare la connessione
        # nginx-rtmp si aspetta un codice HTTP 2xx per permettere lo stream
        return {"status": "accepted", "source_id": source_id}
        
    except Exception as e:
        print(f"❌ Errore in on_publish: {e}")
        # Ritorna comunque 200 per non bloccare lo stream
        return {"status": "error", "message": str(e)}


@router.post("/rtmp/on_publish_done")
async def rtmp_on_publish_done(request: Request):
    """
    Callback chiamato da nginx-rtmp quando uno stream termina la pubblicazione.
    Questo endpoint viene chiamato automaticamente quando uno stream RTMP si disconnette.
    """
    try:
        form_data = await request.form()
        
        app = form_data.get("app", "unknown")
        name = form_data.get("name", "unknown")  # source_id
        addr = form_data.get("addr", "unknown")
        duration = form_data.get("duration", "0")  # Durata in secondi
        
        source_id = name
        
        print(f"📹 RTMP PUBLISH DONE: source_id={source_id}, app={app}, addr={addr}, duration={duration}s")
        
        # Qui potresti voler pulire risorse o notificare il source manager
        # Per ora solo logging
        
        return {"status": "processed", "source_id": source_id}
        
    except Exception as e:
        print(f"❌ Errore in on_publish_done: {e}")
        return {"status": "error", "message": str(e)}


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

