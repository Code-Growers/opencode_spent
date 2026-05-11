import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_remote/openspent_remote.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteExchangeRateRepository', () {
    test('parses ČNB rates for the normalized UTC day', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '03.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      final rates = await repository.readExchangeRatesForDate(
        DateTime.parse('2026-05-02T23:30:00-07:00'),
      );

      expect(apiClient.requestedDate, '03.05.2026');
      expect(rates, <ExchangeRate>[
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 3),
          rateToCzk: 21.93,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 3),
          rateToCzk: 1.0,
        ),
      ]);
    });

    test('rejects parsed date mismatches clearly', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '02.05.2026 #84\n'
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
            'ČNB returned rates for 02.05.2026 when 03.05.2026 was requested.',
          ),
        ),
      );
    });

    test('normalizes positive-offset instants by UTC day', () async {
      final apiClient = _FakeCnbExchangeRateApiClient(
        response:
            '02.05.2026 #84\n'
            'země|měna|množství|kód|kurz\n'
            'USA|dollar|1|USD|21,930\n',
      );
      final repository = RemoteExchangeRateRepository(apiClient: apiClient);

      final rates = await repository.readExchangeRatesForDate(
        DateTime.parse('2026-05-03T00:30:00+02:00'),
      );

      expect(apiClient.requestedDate, '02.05.2026');
      expect(rates, <ExchangeRate>[
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 2),
          rateToCzk: 21.93,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 2),
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
