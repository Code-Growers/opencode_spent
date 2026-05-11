# openspent_local

`openspent_local` provides Flutter-compatible local repository adapters for `openspent_core`.

This Phase 2 slice stays local-only: settings use an injected preferences backend with a production `shared_preferences` adapter, while sessions and exchange rates use a local Drift-backed cache database.

## Analyze

```bash
flutter analyze
```

## Test

```bash
flutter test
```

## CLI ingestion

Import OpenCode exports into a chosen local OpenSpent database file:

```bash
dart run bin/ingest.dart import-json <source.json> --db <local.db>
dart run bin/ingest.dart import-sqlite <opencode.db> --db <local.db>
```

The CLI stays local-only and prints only a minimal success or failure summary.
