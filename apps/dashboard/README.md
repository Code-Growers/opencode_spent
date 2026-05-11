# openspent_dashboard

`openspent_dashboard` is the Flutter application for the OpenSpent workspace.

The dashboard currently ships a monochromatic, terminal-inspired local dashboard on top of `openspent_core`, including persisted settings, local cache bootstrap, connection status, richer text summaries, 7-day spend and token charts, selected-day hourly drilldowns, and the accepted models breakdown.

It remains privacy-first and local-only: development tests still use injected fake services, while the production app bootstraps real local settings, a local SQLite cache, and locally derived OpenCode metrics.

## Run

```bash
flutter run -d macos
```

## Analyze

```bash
flutter analyze
```

## Test

```bash
flutter test
```

## Build

```bash
flutter build macos
```
