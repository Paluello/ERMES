"""Sistema di aggiornamento automatico con polling GitHub"""
import asyncio
import subprocess
import os
import logging
from typing import Optional
from datetime import datetime
import httpx

logger = logging.getLogger(__name__)


class AutoUpdater:
    """Gestisce l'aggiornamento automatico via polling GitHub"""
    
    def __init__(
        self,
        github_repo: str,
        github_branch: str = "main",
        github_token: Optional[str] = None,
        poll_interval_minutes: int = 5,
        update_script_path: str = "/app/update_container.sh"
    ):
        self.github_repo = github_repo
        self.github_branch = github_branch
        self.github_token = github_token
        self.poll_interval_seconds = poll_interval_minutes * 60
        self.update_script_path = update_script_path
        self.last_commit_sha: Optional[str] = None
        self.is_running = False
        self._task: Optional[asyncio.Task] = None
        
    async def get_latest_commit_sha(self) -> Optional[str]:
        """Ottiene l'SHA dell'ultimo commit dal branch configurato"""
        try:
            url = f"https://api.github.com/repos/{self.github_repo}/commits/{self.github_branch}"
            headers = {}
            
            if self.github_token:
                headers["Authorization"] = f"token {self.github_token}"
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(url, headers=headers)
                response.raise_for_status()
                data = response.json()
                return data.get("sha")
        except Exception as e:
            logger.error(f"Errore nel recupero ultimo commit: {e}")
            return None
    
    async def check_and_update(self) -> bool:
        """Controlla se ci sono nuovi commit e aggiorna se necessario"""
        try:
            latest_sha = await self.get_latest_commit_sha()
            
            if not latest_sha:
                logger.warning("Impossibile recuperare SHA ultimo commit")
                return False
            
            # Prima esecuzione: salva SHA ma non aggiorna
            if self.last_commit_sha is None:
                self.last_commit_sha = latest_sha
                logger.info(f"Polling inizializzato. Ultimo commit: {latest_sha[:7]}")
                return False
            
            # Se l'SHA è cambiato, c'è un nuovo commit
            if latest_sha != self.last_commit_sha:
                logger.info(
                    f"🆕 Nuovo commit rilevato! "
                    f"Vecchio: {self.last_commit_sha[:7]} -> Nuovo: {latest_sha[:7]}"
                )
                
                # Esegui aggiornamento
                if await self.trigger_update():
                    self.last_commit_sha = latest_sha
                    logger.info("✅ Aggiornamento completato con successo")
                    return True
                else:
                    logger.error("❌ Errore durante l'aggiornamento")
                    return False
            
            return False
        except Exception as e:
            logger.error(f"Errore durante controllo aggiornamenti: {e}")
            return False
    
    async def trigger_update(self) -> bool:
        """Esegue lo script di aggiornamento"""
        try:
            if not os.path.exists(self.update_script_path):
                logger.error(f"Script di aggiornamento non trovato: {self.update_script_path}")
                return False
            
            logger.info(f"🚀 Avvio aggiornamento tramite: {self.update_script_path}")
            
            # Esegui script in background (non blocca)
            process = subprocess.Popen(
                ["/bin/bash", self.update_script_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Attendi un po' per vedere se ci sono errori immediati
            await asyncio.sleep(2)
            
            if process.poll() is not None:
                # Processo terminato immediatamente (probabile errore)
                stdout, stderr = process.communicate()
                logger.error(f"Script terminato con errore: {stderr}")
                return False
            
            logger.info(f"Script avviato in background (PID: {process.pid})")
            return True
            
        except Exception as e:
            logger.error(f"Errore durante esecuzione script aggiornamento: {e}")
            return False
    
    async def _polling_loop(self):
        """Loop principale di polling"""
        logger.info(
            f"🔄 Polling automatico avviato: "
            f"controllo ogni {self.poll_interval_seconds // 60} minuti"
        )
        
        while self.is_running:
            try:
                await self.check_and_update()
            except Exception as e:
                logger.error(f"Errore nel loop di polling: {e}")
            
            # Attendi prima del prossimo controllo
            await asyncio.sleep(self.poll_interval_seconds)
    
    def start(self):
        """Avvia il polling automatico"""
        if self.is_running:
            logger.warning("Polling già in esecuzione")
            return
        
        self.is_running = True
        self._task = asyncio.create_task(self._polling_loop())
        logger.info("✅ Auto-updater avviato")
    
    def stop(self):
        """Ferma il polling automatico"""
        if not self.is_running:
            return
        
        self.is_running = False
        if self._task:
            self._task.cancel()
        logger.info("⏹ Auto-updater fermato")
    
    async def force_check(self) -> bool:
        """Forza un controllo immediato (utile per test)"""
        return await self.check_and_update()

