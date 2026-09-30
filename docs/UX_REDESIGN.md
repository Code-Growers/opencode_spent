# OpenSpent UX redesign

## Outcome

One visual language across the marketing site, Flutter web, desktop and CLI:
Code Growers' near-black canvas, Necto Mono, vivid green, square controls and fine
rules. Existing calculation, sync, import, pricing and privacy logic remains the
source of truth.

## Problems and implementation plan

1. **Competing scroll areas** — replace the dashboard's outer NestedScrollView
   with a fixed workspace shell. Each route owns one vertical scroll area.
   Sessions use pages of 25 naturally sized rows; exchange rates do not nest a
   second vertical scroll view. Horizontal scrolling is reserved for wide data.
2. **Orientation** — persist numbered navigation, show a compact page title and
   purpose, and display the active Real/Mock mode in the header. Wide windows
   use a left navigation column; smaller windows use a compact navigation grid.
   Put attribution in the fixed shell footer.
3. **Data hierarchy** — show time controls and headline KPIs before the harness
   comparison and detailed charts. Keep shell-owned filters and revisions.
4. **Settings usability** — keep the dialog bounded to the viewport with one
   scrolling form and a visible title and action bar.
5. **Marketing journey** — product promise → illustrative dashboard → supported
   sources and capabilities → three ways to start → privacy and team use →
   maker attribution. Add anchor navigation, skip link, accurate setup links,
   English/Czech copy and clear labels for sample data and API estimates.
6. **On-demand CLI** — discover all three supported harnesses locally; allow
   explicit source paths, harness and UTC time filters, pricing overrides and
   JSON output. Reuse the same metadata parsers and pricing calculator. No
   prompts, payloads, absolute project roots or outgoing usage telemetry.

## Acceptance checks

- Navigation remains reachable after scrolling; one vertical scrolling owner
  per dashboard route at wide and narrow viewport sizes.
- Metrics, sessions, exchange rates and settings continue to work in Real and
  Mock modes with English and Czech labels and keyboard focus.
- Pagination, searching, sorting and filter changes preserve access to every
  matching session without creating an independently scrolling list.
- Website anchors, language switching, demo and setup links work at desktop and
  mobile widths. No fabricated download or setup actions.
- CLI discovers supported sources, tolerates missing sources, reports partial
  pricing and failures honestly, and prints only numeric summaries.
- Flutter tests, local adapter/core tests, website tests, Melos analysis,
  website build and Flutter web build pass. Inspect rendered dashboard and
  website previews before delivery.

## Implemented and verified — 30 September 2026

All six workstreams are implemented. Sessions exposes the shell's time window
and can clear a model/day/hour scope; Sources & status exposes local connections
in Real mode. The nested route has its own semantics boundary so fixed navigation
remains available to screen readers. Settings and help have fixed dialog controls
and one scrolling body. The marketing site retains deterministic hook-based
English/Czech localization.

- Dashboard: **142 tests passed**, including Real/Mock layouts at 390, 900 and
  1400 pixels, a single vertical scroll owner, pagination and accessible navigation.
- Core: **47 tests passed**. Local adapters and CLI: **35 tests passed**. Website:
  **3 tests passed**, covering the complete journey, links and language switching.
- Melos analysis: no issues. Marketing static build and Flutter web release build
  succeeded. Browser previews were inspected at desktop and mobile widths;
  session paging/search, settings, exchange rates and Real/Mock switching worked.
- The standalone CLI compiled and completed a live scan of OpenCode, Claude Code
  and Codex, as well as fixture tests for privacy, partial/unknown pricing,
  duplicate archives, missing sources and date filters.
- macOS desktop build succeeded using a temporary Xcode invocation with
  `MACOSX_DEPLOYMENT_TARGET=12.0`. Installed Xcode 27 rejects the project's existing
  10.15 target; the repository's supported OS targets were not changed. A normal
  build on this host still needs that build override or a compatible Xcode.

Local screenshots are under `build/ux-preview/` (ignored build outputs). The
combined local preview serves the website at `/` and Flutter dashboard at `/demo/`.
Changes have not been deployed or published.
