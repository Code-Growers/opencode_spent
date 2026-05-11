# openspent_remote

`openspent_remote` is the pure Dart remote adapter package for OpenSpent. It currently covers reading ČNB exchange rates over HTTP and reading OpenCode sessions/messages from a local OpenCode server API, while leaving persistence/cache responsibilities to `openspent_local`.

## Build

Generate Retrofit client code when the API surface changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Analyze

```bash
dart analyze .
```

## Test

```bash
dart test
```
