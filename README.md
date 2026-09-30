# OpenSpent

OpenSpent is a privacy-first, local-only monorepo for tracking, analyzing, and visualizing OpenCode, Claude Code, and Codex AI usage and cost data.

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

## Current Capabilities

- Multi-currency cost tracking with USD, CZK, and EUR support.
- Local SQLite caching for exchange rates and session metadata.
- Real-time connection to a local OpenCode server.
- Manual SQLite and JSON log ingestion.
- A monochromatic, terminal-inspired dashboard and marketing site.

## Local Claude Code and Codex usage

In the desktop dashboard, open **Settings → Local usage sources** and connect
Claude Code or Codex. OpenSpent discovers local transcript folders, including
Codex archives; **Choose folder** supports custom installations. Connections
refresh at launch and with **Refresh**. Disconnecting keeps imported history.
`CLAUDE_CONFIG_DIR` and `CODEX_HOME` are respected when set in the app's environment.
The browser dashboard retains its existing OpenCode imports and does not scan
local source directories.

The harness filter applies to Metrics and Sessions. Usage includes input, output,
cache reads/writes (with Claude's cache lifetimes), and available reasoning counts.
Input includes cached tokens; reasoning is already included in output. New
transcript usage is attributed to its occurrence time, rather than session start.
Prompts, tool payloads, account details, and project paths are never imported.
Only locally recorded usage is available; missing logs and cloud-only work are
outside the totals.

**Estimated API cost** is separate from **reported cost**. It uses an offline,
versioned snapshot of standard [OpenAI API prices](https://developers.openai.com/api/docs/pricing)
and [Anthropic API prices](https://platform.claude.com/docs/en/about-claude/pricing),
including cache prices and supported context tiers. It excludes subscriptions,
taxes, tool-service charges, and fast-mode premiums. Missing prices are shown as
unavailable, with coverage for partially priced totals. Settings also supports
explicit model mappings and custom USD-per-million-token rates; changes immediately
recalculate estimates from stored token metadata. Blank cache rates leave usage
in that category unpriced; zero is an explicit free rate. Missing context or cache
lifetime metadata is disclosed where a standard-rate fallback is used.

## Workspace Layout

```text
.
├── apps/
│   ├── dashboard/
│   └── website/
├── packages/
│   ├── core/
│   ├── openspent_local/
│   └── openspent_remote/
├── AGENTS.md
└── DESIGN.md
```

## Documentation

- [AGENTS.md](./AGENTS.md) — Operational guardrails, architecture patterns, and agent-specific guidance.
- [DESIGN.md](./DESIGN.md) — Visual authority, theme tokens, and dashboard UI/UX rules.

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

## Combined Web Container

The repo root now includes a combined web deployment container that builds both web apps and serves them from a single nginx document root:

- marketing site at `/`
- dashboard web app at `/demo/`

Build the combined image from the repository root:

```bash
docker build -t openspent-web .
```

Run it locally:

```bash
docker run --rm -p 8080:80 openspent-web
```

Then open:

- `http://localhost:8080/` for the marketing site
- `http://localhost:8080/demo/` for the dashboard

This root Dockerfile builds the Jaspr website and the Flutter dashboard web app, including `flutter build web --release --base-href /demo/`, and copies the dashboard output into a real `demo/` subdirectory under nginx's web root.

If you enable browser-origin CORS for the OpenCode server, allow the page origin only. Do not include `/demo` in the `--cors` origin value. For local use, allow `http://localhost:8080`, not `http://localhost:8080/demo/`.

## Troubleshooting

- If the dashboard shows `Disconnected` during development, make sure the OpenCode API server is running locally.
- If session discovery looks empty, run OpenCode at least once in the target project directory.
- If SQLite-backed data looks stale, remember that OpenCode may still be writing WAL files (`opencode.db-wal`, `opencode.db-shm`).

## License

OpenSpent is available under the MIT License. See [`LICENSE`](./LICENSE).

## CLI spending summary

The CLI scans local **OpenCode, Claude Code and Codex** records on demand.
It uses the dashboard's parsers, deduplication and offline pricing calculator,
without starting the app, saving transcripts or sending usage over the network.
Use the workspace's pinned Dart SDK (3.11.5).

From the repository root:

```bash
dart run packages/openspent_local/bin/openspent.dart --days 30
```

For a standalone executable:

```bash
mkdir -p build/cli
dart compile exe packages/openspent_local/bin/openspent.dart -o build/cli/openspent
./build/cli/openspent --days 30
./build/cli/openspent --harness codex --from 2026-09-01 --to 2026-09-30 --json
```

Put the compiled executable on your PATH to use `openspent` from any directory.
The default window is all available local usage. `--days` uses a rolling UTC
window; `--from` and `--to` are inclusive UTC calendar dates.

Discovery reads OpenCode's `opencode.db` under `XDG_DATA_HOME/opencode` (default
`~/.local/share/opencode`), Claude's `projects` under `CLAUDE_CONFIG_DIR` (default
`~/.claude`) and Codex's `sessions` and `archived_sessions` under `CODEX_HOME`
(default `~/.codex`). For custom installations, pass `--opencode-db FILE`,
`--claude-dir DIR` or `--codex-dir DIR`. A Codex home includes both current and
archived sessions; a direct sessions folder scans only that folder. The CLI
uses fresh source records rather than the dashboard's retained cache or server.

`--pricing FILE` accepts the same pricing configuration shape as the dashboard:

```json
{
  "overrides": {
    "openai/my-model": {"input": 2, "output": 10, "cachedInput": 0.1}
  },
  "mappings": {}
}
```

Rates are USD per million tokens. CLI pricing is configured independently from
app settings. Both **reported USD spend** and **estimated API cost** are printed;
these are separate views and must not be added together. The priced-record count
shows coverage, and unpriced usage stays unknown. Known amounts are subtotals
when coverage is incomplete. Estimates exclude subscriptions, taxes and extra
service charges. Missing installations are labelled `not-found`; partial or
unreadable sources show sanitized counts without file or project paths.

Exit codes: `0` for a successful scan (including no installed sources), `1` for
read failures or an explicitly unavailable source, and `64` for invalid options.
Run `openspent --help` for all options. The existing import CLI remains available.

The redesign plan and acceptance checks are in [docs/UX_REDESIGN.md](docs/UX_REDESIGN.md).
