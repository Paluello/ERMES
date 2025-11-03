# ⚠️ URGENTE: Revoca Token GitHub Esposto

## Problema Critico

Il tuo token GitHub è stato esposto nei log Docker. **REVOCALO SUBITO**.

## Azioni Immediate

1. **Vai su GitHub:**
   https://github.com/settings/tokens

2. **Trova e revoca il token:**
   - Cerca token che inizia con `github_pat_11BMBEE3Y...`
   - Clicca **Revoke** (Revoca)

3. **Crea nuovo token:**
   - Vai su: https://github.com/settings/tokens
   - Generate new token → Fine-grained token
   - Nome: `ERMES-NAS-Docker`
   - Repository: Seleziona solo `Paluello/ERMES`
   - Permissions:
     - ✅ Repository permissions → Contents: **Read-only**
     - ✅ Repository permissions → Metadata: **Read-only**
   - Generate token
   - **COPIA SUBITO** (lo vedi solo una volta)

4. **Aggiorna `.env` sul NAS:**
   ```bash
   GITHUB_TOKEN=github_pat_NUOVO_TOKEN_QUI
   ```

## Formato Corretto Token

Per token **fine-grained** (github_pat_):
- ✅ Formato: `x-access-token:${GITHUB_TOKEN}`
- ✅ Ho aggiornato i Dockerfile con questo formato

## Nota Importante

Se il repository è **PUBBLICO**, non serve token:
```bash
GITHUB_TOKEN=  # Lascia vuoto
```

Dopo aver revocato il vecchio token e creato uno nuovo, aggiorna il file sul NAS e riprova il build.

