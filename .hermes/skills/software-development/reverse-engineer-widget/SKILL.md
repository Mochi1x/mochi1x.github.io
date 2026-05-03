---
name: reverse-engineer-widget
description: Recreate a third-party widget as a self-hosted copy when embedding is blocked (X-Frame-Options) or proxies fail. Involves analyzing the original's visual design, functionality, and logic to build an identical standalone version.
category: software-development
version: 1.0.0
author: Hermes Agent
---

# Reverse-Engineer Third-Party Widgets

When a third-party widget can't be embedded directly (blocked by `X-Frame-Options`, CSP, or domain locks), and proxy approaches are unreliable, build a self-hosted replica that matches the original's look, feel, and behavior exactly.

---

## When to Use This Skill

**Indicators that you need a full replica instead of a proxy:**

1. **Proxy fails due to domain checks** — Widget scripts detect `window.location.origin` and refuse to run
2. **`document.write` overwrites page** — Proxied HTML uses `document.write` which destroys your wrapper page
3. **React/Next.js SPA** — Widget is a full app that expects to be at its own URL; simple HTML extraction doesn't work
4. **Unreliable CORS proxy** — Free proxies rate-limit or return corrupted responses
5. **User wants clean ownership** — Remove branding/footer, customize styling, own the code
6. **Offline / self-contained requirement** — No external dependencies on the provider's uptime

**Contrast with proxy approach:** Proxying fetches and injects the original widget's HTML. This skill **reimplements** the widget from scratch based on observed behavior.

---

## Process Overview

### Phase 1: Widget Analysis (Inspect the Original)

1. **Capture the rendered DOM**
   - Open widget URL in browser
   - Use DevTools to inspect:
     - Session/card elements (class names, structure)
     - Data attributes (if any)
     - Network requests (API calls, data fetching)
     - JavaScript state (if accessible via console)

2. **Extract structural data**
   ```javascript
   // In browser console:
   const cards = document.querySelectorAll('.session-card, .card, div[style*="padding"]');
   cards.forEach(card => console.log(card.textContent.trim()));
   ```

3. **Take screenshots** for visual reference (colors, fonts, spacing, borders)

4. **Identify timezone/region logic**
   - Note time display format (12h vs 24h, AM/PM indicators)
   - Determine if times shown are in user's local timezone or fixed UTC
   - Check DST handling (if visible)

5. **Map business rules**
   - When does each session start/end in UTC?
   - Weekend behavior (fully closed? partial?)
   - Holiday handling (if visible)
   - "Open" vs "Closed" state thresholds (e.g., opens 5 mins early?)

6. **Download assets** (if needed)
   - Icons/flags (right-click → Save)
   - Fonts (check Network tab for `*.woff2` requests)
   - Background images or SVGs

---

### Phase 2: Rebuild From Scratch

1. **Set up minimal HTML structure**
   ```html
   <!DOCTYPE html>
   <html>
   <head>
     <meta charset="UTF-8">
     <title>Widget</title>
     <!-- Copy needed fonts from original -->
   </head>
   <body>
     <div id="app">…</div>
   </body>
   </html>
   ```

2. **Recreate visual design (CSS)**
   - **Colors:** Extract exact hex/rgba values from computed styles
     ```javascript
     getComputedStyle(card).backgroundColor  // → "rgb(24, 24, 27)"
     ```
   - **Typography:** Note font family, weight, size, line-height
   - **Borders:** radius, width, color
   - **Spacing:** padding, margin, gap values
   - **Shadows:** box-shadow values if present
   - **Dark/light theme:** replicate exact bg colors

3. **Rebuild state logic (JavaScript)**
   - Convert observed rules to code:
     ```javascript
     const sessions = [
       { id: 'sydney', name: 'Sydney', flag: '🇦🇺', startUTC: 22, endUTC: 7 },
       { id: 'tokyo',  name: 'Tokyo',  flag: '🇯🇵', startUTC: 0,  endUTC: 9 },
       { id: 'london', name: 'London', flag: '🇬🇧', startUTC: 8,  endUTC: 17 },
       { id: 'ny',     name: 'New York', flag: '🇺🇸', startUTC: 13, endUTC: 22 }
     ];
     ```
   - Implement local time conversion:
     ```javascript
     const tzOffset = -new Date().getTimezoneOffset() / 60;
     function toLocalHour(utcHour) { return (utcHour + tzOffset + 24) % 24; }
     ```
   - Weekend/weekday logic (test both):
     ```javascript
     const day = now.getUTCDay();
     const isWeekend = day === 0 || day === 6;
     // Or partial: Sunday closed until 22:00 UTC
     if (day === 0 && utcHour < 22) return 'closed';
     ```

4. **Add real-time updates**
   - `setInterval(update, 1000)` for clocks
   - Use `Date.getUTCHours()` / `getUTCHours()` for consistent timezone-agnostic math

5. **Test against original side-by-side**
   - Open original and replica in two windows
   - Compare:
     - Clock times (should match within timezone conversion margin)
     - Open/Closed status at same moment
     - Visual spacing, font sizes, colors
   - Quick `console.log` checks:
     ```javascript
     // Run in both pages
     console.log('Sessions:', sessions.map(s => s.name));
     console.log('Now UTC:', new Date().toISOString());
     ```

---

### Phase 3: Refine & Polish

1. **Remove unwanted attribution**
   - Original had footer? Omit it in replica
   - Keep functional elements only

2. **Optimize for embedding**
   - `overflow: hidden` on html/body
   - `min-height: auto` (not 100vh)
   - Transparent background if needed
   - Auto-width/height to fit Notion

3. **Ensure cross-browser compatibility**
   - Test in Chrome, Firefox (notion uses WebView)
   - No ES6+ features that might break in older WebViews (use `const`/`let` are fine, avoid optional chaining if unsure)

4. **Minify if desired** (optional)
   - Keep readable for future tweaks unless size matters

---

## Key Insights from This Session

### Why the Proxy Failed (and Replica Succeeded)

**Attempted approach:** Proxy widget via `api.allorigins.win`, inject HTML, clean styles.

**Problem:** The original widget is a **React/Next.js SPA**:
- HTML shell contains almost nothing (`<div hidden><!--$--><!--/$--></div>`)
- Actual UI rendered client-side by Next.js runtime
- Styles and content injected dynamically after load
- The proxy only captured the initial empty shell, not the rendered DOM

**Solution:** Rebuild the widget logic in plain HTML/CSS/JS (no framework needed for a simple 4-card status display).

### Common Pitfalls When Reverse-Engineering

| Pitfall | How we caught it |
|---------|------------------|
| **Weekend logic missing** | Compared status badge to original (showed "Closed" on Sunday, ours showed "Open") |
| **Timezone conversion off-by-one** | Verified local time display against browser clock; adjust DST handling if needed |
| **Font mismatch** | Original uses Inter (Google Fonts); replica used system sans — downloaded Inter to match |
| **Card spacing/padding** | Measured via DevTools computed style; replicated `padding: 12px 14px`, `border-radius: 14px` |

### Pattern: Self-Hosted Widget as Fallback

**Decision tree:**
```
Can embed directly? → Yes → Use iframe to original
        ↓ No
Proxy work? → Yes → Use proxy embed page (clean styles/footer)
        ↓ No (SPA, domain lock, document.write)
Build replica? → Yes → Recreate with plain HTML/CSS/JS
```

**Benefits of replica:**
- No dependency on source site uptime
- No rate limits or CORS issues
- Full control over styling, branding, features
- Can add enhancements (alerts, sound, integrations)

**Trade-offs:**
- Must manually update if original changes design
- Need to reverse-engineer any future feature additions
- Requires understanding of widget's business logic

---

## Template: Clean Embed-Ready Widget Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Widget — Embed</title>
  <!-- Copy fonts from original if needed -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    /* Extract exact colors from original via DevTools */
    :root {
      --bg: #0a0a0f;
      --card-bg: #18181b;
      --card-border: #27272a;
      --text-main: #e4e4e7;
      --text-muted: #71717a;
      --accent: #f59e0b;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: var(--bg);
      color: var(--text-main);
      font-family: 'Inter', -apple-system, sans-serif;
      min-height: auto;          /* No 100vh for embed */
      padding: 16px;
      overflow-x: hidden;
    }
    /* Replicate exact card styling */
    .card {
      background: var(--card-bg);
      border: 1.5px solid var(--card-border);
      border-radius: 14px;
      padding: 12px 14px;
    }
    /* … more styles matching original … */
  </style>
</head>
<body>
  <!-- Replicate DOM structure exactly -->
  <div id="badge">…</div>
  <div class="clocks">…</div>
  <div class="grid" id="grid"></div>

  <script>
    // Copy session data & logic
    const sessions = [/* from analysis */];
    function update() { /* match original behavior */ }
    setInterval(update, 1000);
  </script>
</body>
</html>
```

---

## Validation Checklist

Before deploying the replica:

- [ ] **Visual match:** Side-by-side screenshots show identical layout, colors, fonts
- [ ] **Time accuracy:** Both clocks show same time (within timezone-conversion correctness)
- [ ] **Status parity:** Open/Closed state matches original at same moment
- [ ] **Footer removed:** No attribution from original site
- [ ] **No scrollbars:** Embedded in test Notion page, resize block to fit
- [ ] **Works offline:** Load replica directly (without internet) to verify self-containment (if intended)
- [ ] **Cross-browser:** Test in at least Chrome and Firefox
- [ ] **Mobile:** Responsive? Does it break below 320px width?

---

## Related Skills

- `github-pages-widget-site` — hosting the replica as part of a widget library
- `systematic-debugging` — root-cause analysis when proxy approach fails
- `spike` — throwaway experiment to validate widget extraction before full rebuild

---

## Quick Reference

| Situation | Approach |
|-----------|----------|
| Simple static widget | Recreate HTML/CSS from view-source |
| JS-driven widget (non-SPA) | Copy inline script logic; port to vanilla JS |
| React/Next.js SPA | Rebuild as vanilla JS using observed state |
| API-driven widget | Find API endpoint, build custom UI |
| Domain-locked script | Omit script, reimplement logic yourself |

---

## Example: Market Hours Widget Rebuild

**Original:** `https://xauusdjulia.com/forex-market-hours/widget`
**Problem:** Next.js SPA — empty HTML shell, content rendered client-side; proxy only fetched empty shell.
**Solution:** Analysed rendered DOM (4 session cards, local/UTC clocks, badge), extracted session times from visible labels, reverse-engineered UTC hour ranges (Sydney 22–7, Tokyo 0–9, London 8–17, NY 13–22), implemented weekend rules (Sat closed, Sun after 22:00 UTC open, Fri until 22:00 UTC open), replicated Inter + JetBrains Mono fonts, and removed footer.

**Files created:**
- `embed/market-hours-julia.html` — embed-ready version
- `widgets/market-hours-julia.html` (optional full page)

**Validation:** Compared side-by-side with original; status badge matched on weekend vs weekday.

---

## Advanced: Finding Hidden Data Sources

If the original widget fetches data from an API, you might be able to call it directly instead of rebuilding UI:

1. **Check Network tab** for XHR/fetch requests
2. Look for JSON responses containing session data
3. Copy request URL + headers
4. Replicate API call in your replica (respect CORS — may need server-side proxy or JSONP)

If no API is visible and logic is embedded in minified JS:
- Search for strings like `"22:00"`, `"open"`, `"close"` in bundled code
- Unminify with https://beautifier.io
- Extract session arrays/objects
- Port to readable JS

---

## When Not to Rebuild

- Widget is **constantly updated** (you'll spend time chasing changes)
- Widget uses **complex proprietary logic** (e.g., algorithmic indicators you can't replicate without docs)
- Widget requires **authentication / paid API** you don't have access to
- Your replica would **violate ToS or copyright** (check license)

In these cases, consider:
- Contacting provider for an embed-friendly version
- Using an alternative free widget
- Building a fundamentally different UI that shows same data
