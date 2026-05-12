import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_remote/openspent_remote.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteExchangeRateRepository', () {
    test('parses ČNB rates for the normalized UTC day', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '04.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      final rates = await repository.readExchangeRatesForDate(
        DateTime.parse('2026-05-03T23:30:00-07:00'),
      );

      expect(apiClient.requestedDate, '04.05.2026');
      expect(rates, <ExchangeRate>[
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 4),
          rateToCzk: 21.93,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 4),
          rateToCzk: 1.0,
        ),
      ]);
    });

    test(
      'accepts prior working-day ČNB fixings for requested weekends',
      () async {
        final apiClient = _FakeCnbExchangeRateApiClient(
          response:
              '15.05.2026 #84\n'
              'země|měna|množství|kód|kurz\n'
              'USA|dollar|1|USD|21,930\n',
        );
        final repository = RemoteExchangeRateRepository(apiClient: apiClient);

        final rates = await repository.readExchangeRatesForDate(
          DateTime.utc(2026, 5, 16),
        );

        expect(apiClient.requestedDate, '16.05.2026');
        expect(rates, <ExchangeRate>[
          ExchangeRate(
            currency: SupportedCurrency.usd,
            date: DateTime.utc(2026, 5, 15),
            rateToCzk: 21.93,
          ),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 15),
            rateToCzk: 1.0,
          ),
        ]);
      },
    );

    test(
      'accepts prior working-day ČNB fixings across holiday chains',
      () async {
        final apiClient = _FakeCnbExchangeRateApiClient(
          response:
              '23.12.2026 #84\n'
              'země|měna|množství|kód|kurz\n'
              'USA|dollar|1|USD|21,930\n',
        );
        final repository = RemoteExchangeRateRepository(apiClient: apiClient);

        final rates = await repository.readExchangeRatesForDate(
          DateTime.utc(2026, 12, 27),
        );

        expect(apiClient.requestedDate, '27.12.2026');
        expect(rates, <ExchangeRate>[
          ExchangeRate(
            currency: SupportedCurrency.usd,
            date: DateTime.utc(2026, 12, 23),
            rateToCzk: 21.93,
          ),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 12, 23),
            rateToCzk: 1.0,
          ),
        ]);
      },
    );

    test(
      'accepts the previous working-day fixing for the current requested day',
      () async {
        final apiClient = _FakeCnbExchangeRateApiClient(
          response:
              '11.05.2026 #84\n'
              'země|měna|množství|kód|kurz\n'
              'USA|dollar|1|USD|21,930\n',
        );
        final repository = RemoteExchangeRateRepository(
          apiClient: apiClient,
          now: () => DateTime.utc(2026, 5, 12, 8),
        );

        final rates = await repository.readExchangeRatesForDate(
          DateTime.utc(2026, 5, 12),
        );

        expect(apiClient.requestedDate, '12.05.2026');
        expect(rates, <ExchangeRate>[
          ExchangeRate(
            currency: SupportedCurrency.usd,
            date: DateTime.utc(2026, 5, 11),
            rateToCzk: 21.93,
          ),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 11),
            rateToCzk: 1.0,
          ),
        ]);
      },
    );

    test('rejects stale parsed dates after a working day gap', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '15.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      await expectLater(
        () => repository.readExchangeRatesForDate(DateTime.utc(2026, 5, 19)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'ČNB returned rates for 15.05.2026 when 19.05.2026 was requested.',
          ),
        ),
      );
    });

    test('rejects parsed dates that are not Czech working days', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '16.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      await expectLater(
        () => repository.readExchangeRatesForDate(DateTime.utc(2026, 5, 17)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'ČNB returned rates for 16.05.2026 when 17.05.2026 was requested.',
          ),
        ),
      );
    });

    test('rejects future parsed date mismatches clearly', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '04.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      await expectLater(
        () => repository.readExchangeRatesForDate(DateTime.utc(2026, 5, 3)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'ČNB returned rates for 04.05.2026 when 03.05.2026 was requested.',
          ),
        ),
      );
    });

    test('normalizes positive-offset instants by UTC day', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '04.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      final rates = await repository.readExchangeRatesForDate(
        DateTime.parse('2026-05-05T00:30:00+02:00'),
      );

      expect(apiClient.requestedDate, '04.05.2026');
      expect(rates, <ExchangeRate>[
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 4),
          rateToCzk: 21.93,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 4),
          rateToCzk: 1.0,
        ),
      ]);
    });

    test('rejects writeExchangeRates with openspent_local guidance', () async {
      final repository = RemoteExchangeRateRepository(
        apiClient: _FakeCnbExchangeRateApiClient(
          response: '02.05.2026 #84\nzemě|měna|množství|kód|kurz\n',
        ),
      );

      await expectLater(
        () => repository.writeExchangeRates(const <ExchangeRate>[]),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            'RemoteExchangeRateRepository is read-only. Use openspent_local for exchange-rate persistence or caching.',
          ),
        ),
      );
    });
  });
}

final class _FakeCnbExchangeRateApiClient implements CnbExchangeRateApiClient {
  _FakeCnbExchangeRateApiClient({required this.response});

  final String response;
  String? requestedDate;

  @override
  Future<String> getDailyExchangeRateFile({required String date}) async {
    requestedDate = date;
    return response;
  }
}
