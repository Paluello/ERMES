# Token GitHub - Guida Completa

## Quando Serve il Token?

### ✅ NON Serve Token Se:
- Il repository è **PUBBLICO** (chiunque può vederlo)
- Lasci `GITHUB_TOKEN=` vuoto nel file `.env`

### 🔑 Serve Token Se:
- Il repository è **PRIVATO** (solo tu puoi vederlo)
- In questo caso, Docker ha bisogno del token per clonare il codice

## Permessi Necessari

Per repository **PRIVATI**, il token ha bisogno di questi permessi:

### Permesso Principale:
- ✅ **`repo`** - Accesso completo ai repository privati
  - Questo include: clone, pull, push
  - Necessario per Docker che deve clonare il codice

### Permessi Opzionali (non necessari per ERMES):
- ❌ `admin:repo_hook` - Non serve
- ❌ `delete_repo` - Non serve
- ❌ `workflow` - Non serve

## Come Creare il Token

### Passo 1: Vai alle Impostazioni GitHub

1. Apri GitHub nel browser: https://github.com
2. Clicca sulla tua **foto profilo** (in alto a destra)
3. Clicca **Settings**
4. Nel menu sinistro, cerca **Developer settings** (in fondo)
5. Clicca **Personal access tokens**
6. Clicca **Tokens (classic)** o **Fine-grained tokens**

### Passo 2: Crea Nuovo Token

**Opzione A: Token Classico (Consigliato)**

1. Clicca **Generate new token** → **Generate new token (classic)**
2. Dai un nome descrittivo: `ERMES-NAS-Docker`
3. Seleziona scadenza:
   - **No expiration** (per comodità)
   - Oppure scegli una data (più sicuro)
4. Seleziona permessi:
   - ✅ Spunta **`repo`** (questo seleziona automaticamente tutti i sotto-permissi)
     - ✅ `repo:status`
     - ✅ `repo_deployment`
     - ✅ `public_repo`
     - ✅ `repo:invite`
     - ✅ `security_events`
5. Clicca **Generate token** (in fondo)

**Opzione B: Fine-Grained Token (Più Sicuro)**

1. Clicca **Generate new token** → **Generate new token (fine-grained)**
2. Nome: `ERMES-NAS-Docker`
3. Scadenza: scegli preferenza
4. Repository access:
   - Seleziona **Only select repositories**
   - Scegli il repository `ERMES`
5. Permissions:
   - Repository permissions → **Contents**: **Read-only**
   - Repository permissions → **Metadata**: **Read-only**
6. Clicca **Generate token**

### Passo 3: Copia il Token

⚠️ **IMPORTANTE**: GitHub mostra il token **SOLO UNA VOLTA**!

1. Copia subito il token (è una stringa lunga tipo: `ghp_xxxxxxxxxxxxxxxxxxxx`)
2. Salvalo in un posto sicuro temporaneamente
3. **NON condividerlo mai** pubblicamente

### Passo 4: Usa il Token nel NAS

Nel file `.env` sul NAS, aggiungi:

```bash
GITHUB_REPO=TUO-USERNAME/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx  # Il token che hai copiato
```

## Esempio Completo

### Scenario 1: Repository Pubblico

```bash
# File .env sul NAS
GITHUB_REPO=mattiapaluello/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=  # Lasciato vuoto - non serve!
```

### Scenario 2: Repository Privato

```bash
# File .env sul NAS
GITHUB_REPO=mattiapaluello/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=ghp_1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t  # Token reale
```

## Sicurezza Token

### ✅ Buone Pratiche:

1. **Non committare il token nel repository**
   - Il file `.env` dovrebbe essere in `.gitignore`
   - Usa `.env.example` senza token

2. **Limita permessi**
   - Usa solo permessi necessari (`repo` per privati)
   - Fine-grained token è più sicuro (solo repository specifico)

3. **Ruota il token periodicamente**
   - Crea nuovo token ogni 6-12 mesi
   - Revoca vecchi token non usati

4. **Non condividere il token**
   - Non metterlo in chat, email, documenti pubblici
   - Solo sul NAS (file `.env`)

### 🔒 Se il Token viene Compromesso:

1. Vai su GitHub → Settings → Developer settings → Personal access tokens
2. Trova il token compromesso
3. Clicca **Revoke** (revoca)
4. Crea nuovo token
5. Aggiorna `.env` sul NAS

## Verifica Token Funziona

Puoi testare se il token funziona:

```bash
# Dal Mac o NAS (se hai curl)
curl -H "Authorization: token TUO_TOKEN" https://api.github.com/user

# Dovresti vedere informazioni del tuo account
```

## Troubleshooting

### Errore: "Repository not found"

**Causa**: Token non ha permessi o repository è privato senza token

**Soluzione**:
- Verifica che `GITHUB_REPO` sia corretto (formato: `username/repo`)
- Se repo è privato, aggiungi `GITHUB_TOKEN` valido
- Verifica che token abbia permesso `repo`

### Errore: "Authentication failed"

**Causa**: Token scaduto o non valido

**Soluzione**:
- Controlla che token non sia scaduto su GitHub
- Rigenera nuovo token se necessario
- Verifica che `GITHUB_TOKEN` nel `.env` sia corretto (senza spazi)

### Errore: "Permission denied"

**Causa**: Token non ha permessi sufficienti

**Soluzione**:
- Assicurati che token abbia permesso `repo` (per repo privati)
- Per fine-grained token, verifica che repository sia selezionato

## Riepilogo Permessi

| Tipo Repository | Token Necessario? | Permessi Minimi |
|-----------------|-------------------|-----------------|
| **Pubblico** | ❌ NO | Nessuno |
| **Privato** | ✅ SÌ | `repo` (read access) |

## Link Utili

- Crea token: https://github.com/settings/tokens
- Documentazione GitHub: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- Gestisci token: https://github.com/settings/tokens

