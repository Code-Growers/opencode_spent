import 'dart:convert';

import 'package:openspent_core/openspent_core.dart';

import '../preferences/key_value_store.dart';

final class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._store, {this.storageKey = _defaultStorageKey});

  static const _defaultStorageKey = 'openspent.settings';
  static const _languageCodeJsonKey = 'languageCode';
  static const _serverUsernameJsonKey = 'openCodeServerUsername';
  static const _serverPasswordJsonKey = 'openCodeServerPassword';

  final KeyValueStore _store;
  final String storageKey;

  @override
  Future<OpenCodeSettings?> readSettings() async {
    final rawValue = await _store.readString(storageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Expected settings storage to contain a JSON object.',
      );
    }

    final currencyCode = decoded['selectedCurrency'];
    final serverUrl = decoded['openCodeServerUrl'];
    final languageCode = decoded[_languageCodeJsonKey];
    final serverUsername = decoded[_serverUsernameJsonKey];
    final serverPassword = decoded[_serverPasswordJsonKey];

    if (currencyCode is! String || serverUrl is! String) {
      throw const FormatException(
        'Expected persisted settings to contain selectedCurrency and openCodeServerUrl strings.',
      );
    }

    if (languageCode != null && languageCode is! String) {
      throw const FormatException(
        'Expected persisted languageCode to be a string when present.',
      );
    }

    if (serverUsername != null && serverUsername is! String) {
      throw const FormatException(
        'Expected persisted openCodeServerUsername to be a string when present.',
      );
    }

    if (serverPassword != null && serverPassword is! String) {
      throw const FormatException(
        'Expected persisted openCodeServerPassword to be a string when present.',
      );
    }

    final currency = SupportedCurrency.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException('Unsupported persisted currency: $currencyCode');
    }

    final parsedUri = Uri.tryParse(serverUrl);
    if (parsedUri == null) {
      throw FormatException(
        'Invalid persisted OpenCode server URL: $serverUrl',
      );
    }

    return OpenCodeSettings(
      selectedCurrency: currency,
      openCodeServerUrl: parsedUri,
      languageCode: languageCode as String?,
      openCodeServerUsername: serverUsername as String?,
    );
  }

  @override
  Future<void> writeSettings(OpenCodeSettings settings) async {
    final payload = <String, Object?>{
      'selectedCurrency': settings.selectedCurrency.code,
      'openCodeServerUrl': settings.openCodeServerUrl.toString(),
      _languageCodeJsonKey: settings.languageCode,
      _serverUsernameJsonKey: settings.openCodeServerUsername,
      _serverPasswordJsonKey: null,
    };

    await _store.writeString(storageKey, jsonEncode(payload));
  }
}
