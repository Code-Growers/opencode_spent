# OpenSpent Agent Guide

## Workspace layout

- `pubspec.yaml` at the repo root is the workspace toolchain package. It owns Melos/dev tooling and the root `pubspec.lock`.
- `apps/dashboard` is the Flutter desktop dashboard.
- `apps/website` is the Jaspr static marketing site.
- `packages/core` is pure Dart domain logic, contracts, parsers, privacy constants, and sync services.
- `packages/openspent_local` contains local adapters: Drift/SQLite repositories plus shared-preferences-backed settings storage.
- `packages/openspent_remote` contains remote adapters: Dio/Retrofit clients and repositories.

## Privacy and data-handling constraints

- Keep the product local-first and privacy-first.
- Do not surface prompts or raw tool payloads. `OpenSpentInfo.sensitiveFieldsDenylist` explicitly blocks `prompt`, `state.input`, `state.output`, and `state.error`.
- Persist and display only allowlisted metadata. Current allowlists live in `packages/core/lib/src/info/openspent_info.dart`.
- Do not introduce features that expose absolute project roots or other sensitive local-machine details.

## Current dashboard architecture

- `apps/dashboard/lib/main.dart` is the composition root. It wires repositories/services from `openspent_core`, `openspent_local`, and `openspent_remote`, then launches `OpenSpentApp`.
- `apps/dashboard/lib/src/app/open_spent_app.dart` owns app locale state and wraps `MaterialApp.router` in `OpenSpentAppScope`.
- `apps/dashboard/lib/src/app/app_scope.dart` provides app-scoped dependencies and `onLocaleChanged`.
- `apps/dashboard/lib/src/app/app_router.dart` defines the `auto_route` tree. `DashboardShellRoute` is the shell with nested metrics, sessions, exchange-rates, and settings routes.
- `apps/dashboard/lib/src/screens/dashboard/dashboard_shell_screen.dart` owns shared shell state: persisted settings load, server probe loop, window/model/day/hour filters, and metrics/sessions/exchange-rate revision counters. It also builds the child route content.
- Feature state stays screen-local. The current cubits live under `apps/dashboard/lib/src/screens/*/cubit/` (`metrics`, `sessions`, `exchange_rates`). Do not move shell-owned cross-screen state into those cubits unless the architecture is intentionally being changed.

## Persisted settings contract

- The settings model is `OpenCodeSettings` in `packages/core/lib/src/models/open_code_settings.dart`.
- Persisted JSON is written by `LocalSettingsRepository` in `packages/openspent_local/lib/src/repositories/local_settings_repository.dart`.
- The persisted keys are exactly:
  - `selectedCurrency`
  - `openCodeServerUrl`
  - `languageCode`
- `languageCode` is already implemented in the shipped dashboard. Treat older notes claiming language switching is pending as stale.

## Dashboard operational guardrails

- **Visual Authority**: `DESIGN.md` at the repo root is the canonical guide for UI/UX. Match theme tokens, typography, and layout rules defined there.
- **State Ownership**: `DashboardShellScreen` owns cross-screen state (filters, probe loops, revision counters). Feature cubits stay screen-local under `apps/dashboard/lib/src/screens/*/cubit/`.
- **Localization Workflow**: Run `dart run melos run generate:l10n` to update translations. Never manually edit `apps/dashboard/lib/l10n/app_localizations*.dart`.
- **Generated Code**: Do not hand-edit files ending in `.g.dart`, `.gr.dart`, or generated localization files. Use Melos `generate` scripts to refresh them.
- **Branding**: Attribution and versioning live in the dashboard shell footer. Reference `apps/dashboard/lib/src/app/dashboard_build_info.dart` and `apps/dashboard/web/logo.svg`.
- **Build Version Sync**: Keep `apps/dashboard/lib/src/app/dashboard_build_info.dart` aligned with the package version in `apps/dashboard/pubspec.yaml` until release automation owns that value.
- **Testing**: UI changes require verification in both Real and Mock data modes. Run `flutter test` in `apps/dashboard`.

## Package responsibilities

- `packages/core`: pure Dart models, repository interfaces, calculators/composers, parsers, sync services, and shared product/privacy constants.
- `packages/openspent_local`: local persistence and import adapters (`OpenSpentLocalDatabase`, local repositories, SQLite import, shared preferences storage).
- `packages/openspent_remote`: network access only (`RemoteExchangeRateRepository`, `RemoteOpenCodeSessionRepository`, Retrofit clients, generated `.g.dart` files).
- Keep Flutter-specific UI concerns in `apps/dashboard`; do not move them into `packages/core`.

## Code generation and workspace workflow

- Workspace orchestration lives in the root `pubspec.yaml` under the `melos:` section (Melos 7.x).
- `dart run melos run generate` currently runs:
  - `generate:drift`
  - `generate:retrofit`
  - `generate:auto-route`
- `generate:l10n` exists as a separate Melos script and is not part of the aggregate `generate` script.
- When dependency or annotated source changes affect generated files, regenerate them instead of hand-editing generated outputs.

## Guardrails for future agents

- Match the existing separation of concerns: shell-owned shared dashboard state, screen-local cubits, pure-Dart core contracts, local adapters in `openspent_local`, remote adapters in `openspent_remote`.
- Preserve `resolution: workspace`, workspace membership, Flutter SDK dependencies, and path dependencies unless the task explicitly changes workspace structure.
- Prefer architecture-faithful updates over roadmap assumptions. `prompts/implementation_steps.md` is useful context, but some dashboard notes in it are stale.
- Do not edit generated files manually unless regeneration is impossible and the task explicitly requires it.
- Validate with the Melos workflow after meaningful changes.
