"""Variabili globali applicazione"""
from app.sources.source_manager import SourceManager
from app.orchestrator import TrackingOrchestrator
from typing import Optional

# SourceManager globale (singleton)
source_manager = SourceManager()

# Orchestratore globale
_orchestrator: Optional[TrackingOrchestrator] = None

def set_orchestrator(orchestrator: Optional[TrackingOrchestrator]):
    """Imposta orchestratore globale"""
    global _orchestrator
    _orchestrator = orchestrator

def get_orchestrator() -> Optional[TrackingOrchestrator]:
    """Ottieni orchestratore globale"""
    return _orchestrator

