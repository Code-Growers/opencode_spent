# openspent_website

OpenSpent's Jaspr static marketing site uses Tailwind CSS and local English/Czech localization.

## Build

From the repository root, using the pinned Flutter/Dart toolchain:

```bash
flutter pub get --enforce-lockfile
dart run melos run build:website
```

Or from `apps/website`:

```bash
sh ../../tool/build_website.sh
```

The output is `apps/website/build/jaspr`. Keep port `8081` free during the build; Jaspr uses it to render static routes.

## Why the build is isolated

Jaspr 0.23.5's builder needs analyzer 12, while the Flutter workspace's existing generators and test framework need analyzer 10. Its CLI also conflicts with Melos 7's dependencies. `tool/build_website.sh` stages website sources in `.dart_tool/website_build` and builds with the separate checked-in manifest and lockfile in `tool/website_build`.

The CLI and build runner therefore share one resolved `build_daemon` version. No globally installed CLI is used, and the existing workspace SDK, database packages, and dashboard generators stay compatible.

When upgrading Jaspr, update its runtime/test versions in this package and the matching runtime/builder/CLI versions in `tool/website_build/pubspec.yaml`, then regenerate both lockfiles. Source edits belong in `apps/website/lib` and `apps/website/web`; staging files are disposable build artifacts. Rerun the build to preview changes. Generated entrypoint bindings are refreshed by the build script.

## Analyze and Test

```bash
dart analyze .
dart test
```

## Docker

The root Dockerfile builds the website and Flutter demo with the same build script:

```bash
docker build -t openspent .
docker run -p 8080:80 openspent
```

The website-only image needs only Dart because the isolated website build has no Flutter dependencies:

```bash
docker build -t openspent-website -f apps/website/Dockerfile .
docker run -p 8080:8080 openspent-website
```
