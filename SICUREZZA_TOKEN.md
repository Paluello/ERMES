# ⚠️ SICUREZZA: Token GitHub Esposto

## Problema

Il tuo token GitHub è stato esposto nei log Docker. Questo è un **rischio di sicurezza**.

## Cosa Fare SUBITO

1. **Revoca il token esposto:**
   - Vai su: https://github.com/settings/tokens
   - Trova il token che inizia con `github_pat_11BMBEE3Y09EPoKwz...`
   - Clicca **Revoke** (Revoca)

2. **Crea nuovo token:**
   - Genera nuovo token con permessi `repo`
   - **NON condividere mai il token**

3. **Aggiorna `.env` sul NAS:**
   ```bash
   GITHUB_TOKEN=ghp_NUOVO_TOKEN_QUI
   ```

## Prevenzione Futura

Ho aggiornato i Dockerfile per:
- Usare formato corretto token: `x-access-token:${GITHUB_TOKEN}`
- Filtrare token dai log (non perfetto, ma aiuta)

**Best Practice:**
- Usa repository **PUBBLICO** se possibile (non serve token)
- Se repository privato, considera usar solo per sviluppo/test
- In produzione, usa GitHub Actions o altro sistema CI/CD

## Verifica Repository Pubblico

Se il repository è pubblico, puoi rimuovere il token dal `.env`:

```bash
GITHUB_REPO=Paluello/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=  # Lascia vuoto se pubblico
```

