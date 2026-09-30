# OpenSpent Brand and Dashboard Design System

This is the canonical visual guide for OpenSpent. The dashboard and marketing site share the Code Growers brand, adapted from `cg_web/src/styles/global.css` and https://codegrowers.com/en/.

## Principles

- Local-first and privacy-first: show only allowlisted metadata, never prompts, raw tool payloads, or absolute project roots.
- Use the Code Growers near-black canvas, white typography, vivid green accents, thin rules, and square geometry.
- Keep data readable: the dashboard uses compact brand typography and responsive panels rather than the marketing site's full-height sections.
- Flat surfaces and deliberate spacing: no blue glows, decorative gradients, or rounded pill controls.

## Canonical Theme Tokens

Dashboard tokens live in `apps/dashboard/lib/src/theme/dashboard_colors.dart`.

| Token | Hex | Purpose |
|-------|-----|---------|
| `dashboardBackgroundColor` | `#080808` | Site and app canvas |
| `dashboardSurfaceColor` | `#080808` | Flat outlined panels |
| `dashboardSurfaceElevatedColor` | `#0C0C0C` | Subtle grouping for dense data |
| `dashboardSurfaceHighlightColor` | `#101811` | Selected navigation and controls |
| `dashboardBorderColor` | `#303030` | Grid lines, dividers, panel borders |
| `dashboardPrimaryTextColor` | `#FFFFFF` | Headings and data |
| `dashboardSecondaryTextColor` | `#AAAAAA` | Captions and secondary labels |
| `dashboardAccentColor` | `#39FF82` | Primary actions, charts, focus |
| `dashboardAccentSoftColor` | `#39FF82` | Brand accent compatibility alias |
| `dashboardStatusColor` | `#39FF82` | Connected and successful states |
| `dashboardErrorColor` | `#EF4444` | Errors |

Use black text on filled green actions. Preserve semantic error colors and chart series distinctions.

## Typography

Use the site's **Necto Mono** regular font, bundled locally for offline desktop use in `apps/dashboard/assets/fonts/NectoMono-Regular.ttf`. The original WOFF2 and OFL license are bundled in the website. No font service or runtime download is required.

- Headings: regular weight, slightly negative letter spacing, generous line height.
- Hero: 46px on wide desktop layouts, 32px on compact layouts; green accent.
- Panel titles: regular weight; avoid heavy or widely spaced uppercase headings.
- Body: 1.5 line height, white primary and gray secondary text.
- Eyebrows: small uppercase labels with modest tracking.
- Navigation: regular monospaced labels and subdued two-digit section indices.

## Layout and Controls

- Keep dashboard navigation and the header visible. Each route owns exactly one vertical scroll area; the shell does not scroll. Paginate long session lists instead of creating a second vertical viewport.
- Header: OpenSpent identity with the existing brand logo, active Real/Mock mode, help, and settings.
- Page heading: compact title and purpose. Reserve large framed heroes and registration crosses for the marketing site.
- Navigation: left column from 1180px, equal-width numbered cells on smaller windows and two columns below 640px; green rule and dark green fill indicate selection.
- Lead the overview with time controls and headline totals, followed by harness comparison and detailed charts. Show active filters near the data they affect.
- Settings dialogs use a bounded scrolling form with a fixed heading and save/close actions.
- `DashboardSurface`: one-pixel outline, square corners, solid background, no shadow or gradient. Use it for grouped content throughout all screens.
- Controls: square outlines; white hover inversion, green focus outline, and green selected text. Focus must remain visible without relying on a glow.
- Use `DashboardSpacing` for consistent shell gutters and internal padding. Responsive layouts must wrap labels and controls without clipping.
- KPI cards and terminal panes use the same flat geometry. Charts inherit the green primary accent.
- The marketing site uses the same font, colors, flat panels, outlined actions, and regular-weight headings.

## State and Privacy Boundaries

`DashboardShellScreen` owns cross-screen filters, probes, revisions, and settings loading. Feature cubits stay screen-local. This redesign changes presentation only; retain repository and adapter boundaries and the persisted settings contract.

## Branding and Localization

- Existing logo: `apps/dashboard/web/logo.svg`.
- Attribution and version: dashboard shell footer, using `dashboard_build_info.dart`.
- Keep build version aligned with `apps/dashboard/pubspec.yaml`.
- Edit ARB sources and run `dart run melos run generate:l10n` for translation changes. Never edit generated localization files manually.

## Verification

Run `flutter test` in `apps/dashboard`, including real and mock mode coverage. Verify metrics, sessions, exchange rates, settings, keyboard focus, and constrained desktop layouts. Run the workspace Melos analysis workflow and website tests when changing shared brand presentation. Inspect a rendered preview before delivery.
