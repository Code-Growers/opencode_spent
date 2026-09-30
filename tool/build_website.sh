#!/bin/sh
set -eu

tool_root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repo_root="$(dirname -- "$tool_root")"
source_root="$repo_root/apps/website"
build_root="$repo_root/.dart_tool/website_build"

# Jaspr's analyzer and CLI dependencies conflict with the Flutter workspace.
# Stage only website sources into a separate, lockfile-pinned build package.
mkdir -p "$build_root"
cp "$tool_root/website_build/pubspec.yaml" "$build_root/pubspec.yaml"
cp "$tool_root/website_build/pubspec.lock" "$build_root/pubspec.lock"
rm -rf "$build_root/lib" "$build_root/web"
cp -R "$source_root/lib" "$build_root/lib"
cp -R "$source_root/web" "$build_root/web"

(cd "$build_root" && dart pub get --enforce-lockfile && dart run jaspr_cli:jaspr build)

rm -rf "$source_root/build/jaspr"
mkdir -p "$source_root/build/jaspr"
cp -R "$build_root/build/jaspr/." "$source_root/build/jaspr/"
# Keep generated entrypoint bindings in sync with the upgraded builder.
cp "$build_root/lib/main.client.options.dart" "$source_root/lib/main.client.options.dart"
cp "$build_root/lib/main.server.options.dart" "$source_root/lib/main.server.options.dart"
