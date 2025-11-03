"""FastAPI application entry point"""
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.api import routes, websocket
from app.config import settings
from app.globals import source_manager
from app.orchestrator import TrackingOrchestrator

# Orchestratore globale
orchestrator: TrackingOrchestrator = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestione lifecycle applicazione"""
    global orchestrator
    
    # Startup
    orchestrator = TrackingOrchestrator(source_manager)
    await orchestrator.start_async()
    print("ERMES orchestrator avviato")
    
    yield
    
    # Shutdown
    if orchestrator:
        orchestrator.stop()
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

# WebSocket endpoint
@app.websocket("/ws")
async def websocket_route(websocket: WebSocket):
    await websocket.websocket_endpoint(websocket)


@app.get("/")
async def root():
    return {
        "message": "ERMES API",
        "version": "0.1.0",
        "docs": "/docs"
    }

