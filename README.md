# OpenSpent

OpenSpent is a privacy-first, local-only monorepo for tracking, analyzing, and visualizing OpenCode AI usage and cost data.

The repository is organized into five workspace members:

- `apps/dashboard` — the Flutter dashboard application.
- `apps/website` — the Jaspr static marketing website.
- `packages/core` — a pure Dart package for shared business logic and domain models.
- `packages/openspent_local` — local adapters package for SQLite/shared preferences.
- `packages/openspent_remote` — remote adapters package for Dio/Retrofit network clients.

## Privacy First

OpenSpent is designed to avoid sensitive data exposure:

- It does not display prompts.
- It does not display tool arguments (`state.input`).
- It does not display raw tool output or errors (`state.output`, `state.error`).
- Background task ingestion extracts allowlisted metadata only and derives counts and timestamps locally.
- Source switching uses registered labels instead of exposing absolute project roots.
- All application data stays on the local machine.

## Planned Features

- Multi-currency cost tracking with USD and CZK support.
- Local SQLite caching for exchange rates and session metadata.
- Real-time connection to a local OpenCode server.
- Manual SQLite and JSON log ingestion.
- A monochromatic, terminal-inspired dashboard and marketing site.

## Workspace Layout

```text
.
├── apps/
│   ├── dashboard/
│   └── website/
├── docs/
└── packages/
    ├── core/
    ├── openspent_local/
    └── openspent_remote/
```

## Development

This monorepo uses Melos.

```bash
dart pub get
dart run melos run generate
dart run melos run analyze
dart run melos run test
dart run melos run build:website
```

To run the Flutter dashboard locally:

```bash
cd apps/dashboard
flutter run -d macos
```

The website package contains the Jaspr static app for the marketing site, complete with Tailwind, static EN/CS localization, and a production Dockerfile.

## Troubleshooting

- If the dashboard shows `Disconnected` during development, make sure the OpenCode API server is running locally.
- If session discovery looks empty, run OpenCode at least once in the target project directory.
- If SQLite-backed data looks stale, remember that OpenCode may still be writing WAL files (`opencode.db-wal`, `opencode.db-shm`).

## License

OpenSpent is available under the MIT License. See [`LICENSE`](./LICENSE).
