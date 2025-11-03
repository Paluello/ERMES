"""FastAPI application entry point"""
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from contextlib import asynccontextmanager
from app.api import routes
from app.api import websocket as websocket_module
from app.config import settings
from app.globals import source_manager, get_orchestrator
from app.orchestrator import TrackingOrchestrator
from app.auto_updater import AutoUpdater
import os


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestione lifecycle applicazione"""
    from app.globals import set_orchestrator
    
    # Startup
    orchestrator = TrackingOrchestrator(source_manager)
    set_orchestrator(orchestrator)
    await orchestrator.start_async()
    print("ERMES orchestrator avviato")
    
    # Avvia auto-updater se abilitato
    from app.globals import set_auto_updater
    auto_updater = None
    if settings.github_auto_update_enabled and settings.github_repo:
        update_script = os.getenv("UPDATE_SCRIPT_PATH", "/app/update_container.sh")
        github_token = os.getenv("GITHUB_TOKEN")
        
        auto_updater = AutoUpdater(
            github_repo=settings.github_repo,
            github_branch=settings.github_branch,
            github_token=github_token,
            poll_interval_minutes=settings.github_auto_update_interval_minutes,
            update_script_path=update_script
        )
        auto_updater.start()
        set_auto_updater(auto_updater)
        print(f"✅ Auto-updater avviato: polling ogni {settings.github_auto_update_interval_minutes} minuti")
    else:
        print("ℹ️ Auto-updater disabilitato (configura GITHUB_AUTO_UPDATE_ENABLED=true nel .env)")
    
    yield
    
    # Shutdown
    if auto_updater:
        auto_updater.stop()
        set_auto_updater(None)
        print("Auto-updater fermato")
    
    orchestrator.stop()
    set_orchestrator(None)
    print("ERMES orchestrator fermato")


app = FastAPI(
    title="ERMES - Sistema Tracking e Geolocalizzazione",
    description="Sistema modulare per tracking e geolocalizzazione multi-sorgente",
    version="0.1.0",
    lifespan=lifespan
)

# CORS middleware per frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In produzione, specificare domini esatti
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(routes.router)

# WebSocket endpoint - DISABILITATO TEMPORANEAMENTE
# @app.websocket("/ws")
# async def websocket_route(websocket: WebSocket):
#     await websocket_module.websocket_endpoint(websocket)

# Serve dashboard HTML alla root
@app.get("/")
async def root():
    """Dashboard principale"""
    dashboard_path = os.path.join(os.path.dirname(__file__), "static", "dashboard.html")
    if os.path.exists(dashboard_path):
        return FileResponse(dashboard_path)
    return {
        "message": "ERMES API",
        "version": "0.1.0",
        "docs": "/docs",
        "dashboard": "Dashboard non disponibile"
    }

