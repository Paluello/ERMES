# Architettura Frontend ERMES

## Panoramica

Il frontend di ERMES è stato completamente ristrutturato per essere modulare, coerente e professionale, ispirato ai design system di OpenAI e Vercel.

## Struttura Modulare

```
backend/app/static/
├── design-system.css      # Design system completo e riutilizzabile
├── dashboard.css          # Stili specifici per la dashboard
├── dashboard.html         # Dashboard principale
├── dashboard.js           # Logica JavaScript modulare
└── swagger-custom.css     # CSS personalizzato per Swagger UI
```

## Design System

Il design system (`design-system.css`) fornisce:

### Variabili CSS

- **Colori**: Palette coerente con varianti primary, secondary, success, warning, danger, info
- **Neutrals**: Scala di grigi da 50 a 900
- **Tipografia**: Font system e dimensioni standardizzate
- **Spacing**: Sistema di spaziatura consistente
- **Shadows**: Sistema di ombre gerarchico
- **Borders**: Raggi di bordo standardizzati

### Componenti Base

- **Cards**: Container modulari con hover effects
- **Buttons**: Varianti primary, secondary, ghost con stati
- **Badges**: Indicatori di stato colorati
- **Alerts**: Messaggi informativi/errore
- **Loading States**: Spinner e stati di caricamento
- **Empty States**: Stati vuoti con icone

### Utility Classes

- Layout: `.container`, `.grid`, `.grid-cols-*`
- Typography: `.text-center`, `.text-left`, `.text-right`
- Spacing: `.mt-*`, `.mb-*` (margin top/bottom)

## Dashboard

### Struttura HTML

La dashboard (`dashboard.html`) è strutturata semanticamente:

```html
<header>        <!-- Header con logo e navigazione -->
<main>          <!-- Contenuto principale -->
  <stats-grid>  <!-- Statistiche rapide -->
  <cards-grid>  <!-- Cards informative -->
  <sources>     <!-- Lista sorgenti -->
</main>
```

### JavaScript Modulare

Il file `dashboard.js` implementa una classe `Dashboard` che:

- Gestisce il caricamento dati dalle API
- Implementa auto-refresh ogni 30 secondi
- Gestisce stati di loading/error
- Aggiorna UI in modo reattivo

**Pattern utilizzato:**
- Classe ES6 per incapsulare logica
- Metodi asincroni per chiamate API
- Gestione errori centralizzata
- Event listeners per interazioni utente

## Swagger UI Personalizzato

Il CSS di Swagger (`swagger-custom.css`) è completamente coerente con il design system:

- Stessa palette colori
- Stessi componenti (buttons, cards, inputs)
- Stessa tipografia
- Stessi effetti hover e transizioni

**Configurazione in `main.py`:**
```python
app = FastAPI(
    ...
    swagger_css_url="/static/swagger-custom.css"
)
```

## Coerenza tra Dashboard e Docs

Entrambe le interfacce (`/` e `/docs`) condividono:

1. **Design System**: Stesso file CSS base
2. **Palette Colori**: Identica scala di colori
3. **Tipografia**: Stesso font system
4. **Componenti**: Stessi stili per buttons, cards, badges
5. **Animazioni**: Stesse transizioni e effetti

## Estendibilità

### Aggiungere Nuovi Componenti

1. Definisci variabili CSS nel design system
2. Crea classe componente riutilizzabile
3. Documenta uso e varianti

### Aggiungere Nuove Pagine

1. Crea nuovo HTML che importa `design-system.css`
2. Usa componenti esistenti o crea nuovi
3. Mantieni coerenza con il design system

### Migrazione a React (Futuro)

La struttura modulare attuale facilita la migrazione:

- Design system → CSS Modules o Styled Components
- Componenti HTML → Componenti React
- JavaScript classe → Hooks e Context

## Best Practices

1. **Usa sempre il design system**: Non creare stili custom se esistono nel design system
2. **Mantieni coerenza**: Tutti i componenti devono seguire lo stesso stile
3. **Modularità**: Separa logica (JS), stile (CSS) e struttura (HTML)
4. **Accessibilità**: Usa semantic HTML e ARIA labels
5. **Performance**: Minimizza CSS/JS non utilizzati

## Responsive Design

Il design system include breakpoint responsive:

- **Mobile**: `< 768px` - Layout single column
- **Tablet**: `768px - 1024px` - Layout ottimizzato
- **Desktop**: `> 1024px` - Layout completo

## Browser Support

- Chrome/Edge: Ultime 2 versioni
- Firefox: Ultime 2 versioni
- Safari: Ultime 2 versioni
- Mobile browsers: iOS Safari, Chrome Mobile

## Personalizzazione

Per modificare colori principali, edita le variabili CSS:

```css
:root {
  --color-primary: #6366f1;      /* Cambia colore primario */
  --color-secondary: #8b5cf6;     /* Cambia colore secondario */
  /* ... */
}
```

Tutti i componenti useranno automaticamente i nuovi colori.

## Note Tecniche

- **CSS Variables**: Usate per temi e personalizzazione
- **CSS Grid**: Per layout complessi
- **Flexbox**: Per allineamenti e distribuzione
- **Transitions**: Per animazioni fluide
- **Font Awesome**: Per icone (CDN)

## Riferimenti

- [Design System OpenAI](https://platform.openai.com/docs)
- [Vercel Design](https://vercel.com/design)
- [FastAPI Static Files](https://fastapi.tiangolo.com/tutorial/static-files/)

