"""Variabili globali applicazione"""
from app.sources.source_manager import SourceManager
from app.orchestrator import TrackingOrchestrator
from app.auto_updater import AutoUpdater
from typing import Optional

# SourceManager globale (singleton)
source_manager = SourceManager()

# Orchestratore globale
_orchestrator: Optional[TrackingOrchestrator] = None

# Auto-updater globale
_auto_updater: Optional[AutoUpdater] = None

def set_orchestrator(orchestrator: Optional[TrackingOrchestrator]):
    """Imposta orchestratore globale"""
    global _orchestrator
    _orchestrator = orchestrator

def get_orchestrator() -> Optional[TrackingOrchestrator]:
    """Ottieni orchestratore globale"""
    return _orchestrator

def set_auto_updater(auto_updater: Optional[AutoUpdater]):
    """Imposta auto-updater globale"""
    global _auto_updater
    _auto_updater = auto_updater

def get_auto_updater() -> Optional[AutoUpdater]:
    """Ottieni auto-updater globale"""
    return _auto_updater

