# openspent_website

`openspent_website` is the Jaspr static marketing site for OpenSpent.

This package contains the minimal Jaspr scaffold for the OpenSpent terminal-like landing page, using Tailwind CSS for styling and a simple local static localization layer (EN/CS). The application is built using the `jaspr` framework in static mode.

## Development

Due to workspace dependency resolution, `jaspr_cli` must be run globally. To run the development server with live reload:

```bash
dart pub global activate jaspr_cli 0.23.1
jaspr serve
```

For local static builds, keep port `8081` free. Jaspr's internal renderer uses it during `jaspr build`.

## Build

To build the fully generated static website (HTML/JS/CSS) into `build/jaspr`:

```bash
dart pub global activate jaspr_cli 0.23.1
jaspr build
```

To simply verify compilation within the workspace toolchain (e.g. for CI), run from the workspace root:

```bash
dart run melos run build:website
```

## Analyze and Test

```bash
dart analyze .
dart test
```

## Docker

The Dockerfile resolves the workspace and runs `jaspr build` globally to produce the final static artifacts. To build and serve the production container:

```bash
docker build -t openspent-website -f apps/website/Dockerfile .
docker run -p 8080:8080 openspent-website
```
