import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';

void main() {
  group('LocalSettingsRepository', () {
    test(
      'persists and restores settings through injected key-value storage',
      () async {
        final store = InMemoryKeyValueStore();
        final repository = LocalSettingsRepository(store);
        final settings = OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://127.0.0.1:4096'),
          languageCode: 'cs',
          openCodeServerUsername: 'alice',
          openCodeServerPassword: 'secret',
        );

        await repository.writeSettings(settings);

        expect(
          store.values['openspent.settings'],
          jsonEncode(<String, Object?>{
            'selectedCurrency': 'CZK',
            'openCodeServerUrl': 'http://127.0.0.1:4096',
            'languageCode': 'cs',
            'openCodeServerUsername': 'alice',
            'openCodeServerPassword': null,
          }),
        );
        expect(
          await repository.readSettings(),
          settings.copyWith(openCodeServerPassword: null),
        );
      },
    );

    test(
      'restores settings when persisted payload omits languageCode',
      () async {
        final store = InMemoryKeyValueStore()
          ..values['openspent.settings'] = jsonEncode(<String, Object?>{
            'selectedCurrency': 'USD',
            'openCodeServerUrl': 'http://127.0.0.1:4096',
            'openCodeServerPassword': 'pw-only',
          });

        final repository = LocalSettingsRepository(store);

        expect(
          await repository.readSettings(),
          OpenCodeSettings(
            selectedCurrency: SupportedCurrency.usd,
            openCodeServerUrl: Uri.parse('http://127.0.0.1:4096'),
          ),
        );
      },
    );

    test('persists null languageCode for system locale behavior', () async {
      final store = InMemoryKeyValueStore();
      final repository = LocalSettingsRepository(store);
      final settings = OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://127.0.0.1:4096'),
      );

      await repository.writeSettings(settings);

      expect(
        store.values['openspent.settings'],
        jsonEncode(<String, Object?>{
          'selectedCurrency': 'USD',
          'openCodeServerUrl': 'http://127.0.0.1:4096',
          'languageCode': null,
          'openCodeServerUsername': null,
          'openCodeServerPassword': null,
        }),
      );
      expect(await repository.readSettings(), settings);
    });

    test('does not reload persisted raw password into settings', () async {
      final store = InMemoryKeyValueStore()
        ..values['openspent.settings'] = jsonEncode(<String, Object?>{
          'selectedCurrency': 'USD',
          'openCodeServerUrl': 'http://127.0.0.1:4096',
          'openCodeServerUsername': '',
          'openCodeServerPassword': 'secret',
        });

      final repository = LocalSettingsRepository(store);
      final settings = await repository.readSettings();

      expect(settings?.openCodeServerUsername, '');
      expect(settings?.openCodeServerPassword, isNull);
      expect(settings?.hasServerBasicAuth, isFalse);
      expect(settings?.effectiveOpenCodeServerUsername, isNull);
      expect(settings?.openCodeServerAuthorizationHeader, isNull);
    });

    test('returns null when settings were never stored', () async {
      final repository = LocalSettingsRepository(InMemoryKeyValueStore());

      expect(await repository.readSettings(), isNull);
    });

    test('fails clearly for unsupported persisted currency values', () async {
      final store = InMemoryKeyValueStore()
        ..values['openspent.settings'] = jsonEncode(<String, Object?>{
          'selectedCurrency': 'GBP',
          'openCodeServerUrl': 'http://127.0.0.1:4096',
        });

      final repository = LocalSettingsRepository(store);

      expect(
        repository.readSettings,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Unsupported persisted currency: GBP',
          ),
        ),
      );
    });
  });
}

final class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
