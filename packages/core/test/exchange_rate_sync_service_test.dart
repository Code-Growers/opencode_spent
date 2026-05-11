import 'package:openspent_core/openspent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExchangeRateSyncService', () {
    test('passes remote exchange rates through to local write', () async {
      final date = DateTime.utc(2026, 5, 2);
      final rates = <ExchangeRate>[
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: date,
          rateToCzk: 22.84,
        ),
      ];
      final remoteRepository = _SpyExchangeRateRepository(
        readExchangeRatesResult: rates,
      );
      final localRepository = _SpyExchangeRateRepository();
      final service = ExchangeRateSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      );

      await service.syncExchangeRatesForDate(date);

      expect(remoteRepository.readExchangeRatesCallCount, 1);
      expect(remoteRepository.lastReadDate, date);
      expect(localRepository.writeExchangeRatesCallCount, 1);
      expect(localRepository.writtenExchangeRates, same(rates));
    });

    test('does not call local write when remote read fails', () async {
      final date = DateTime.utc(2026, 5, 2);
      final error = StateError('remote read failed');
      final remoteRepository = _SpyExchangeRateRepository(readError: error);
      final localRepository = _SpyExchangeRateRepository();
      final service = ExchangeRateSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      );

      await expectLater(
        service.syncExchangeRatesForDate(date),
        throwsA(same(error)),
      );

      expect(remoteRepository.readExchangeRatesCallCount, 1);
      expect(remoteRepository.lastReadDate, date);
      expect(localRepository.writeExchangeRatesCallCount, 0);
      expect(localRepository.writtenExchangeRates, isNull);
    });

    test('bubbles local write failures unchanged', () async {
      final date = DateTime.utc(2026, 5, 2);
      final rates = <ExchangeRate>[
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: date,
          rateToCzk: 22.84,
        ),
      ];
      final error = StateError('local write failed');
      final remoteRepository = _SpyExchangeRateRepository(
        readExchangeRatesResult: rates,
      );
      final localRepository = _SpyExchangeRateRepository(writeError: error);
      final service = ExchangeRateSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      );

      await expectLater(
        service.syncExchangeRatesForDate(date),
        throwsA(same(error)),
      );

      expect(remoteRepository.readExchangeRatesCallCount, 1);
      expect(remoteRepository.lastReadDate, date);
      expect(localRepository.writeExchangeRatesCallCount, 1);
      expect(localRepository.writtenExchangeRates, same(rates));
    });
  });
}

final class _SpyExchangeRateRepository implements ExchangeRateRepository {
  _SpyExchangeRateRepository({
    List<ExchangeRate>? readExchangeRatesResult,
    this.readError,
    this.writeError,
  }) : _readExchangeRatesResult = readExchangeRatesResult ?? <ExchangeRate>[];

  final List<ExchangeRate> _readExchangeRatesResult;
  final Object? readError;
  final Object? writeError;

  int readExchangeRatesCallCount = 0;
  int writeExchangeRatesCallCount = 0;
  DateTime? lastReadDate;
  Iterable<ExchangeRate>? writtenExchangeRates;

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    readExchangeRatesCallCount += 1;
    lastReadDate = date;

    if (readError != null) {
      throw readError!;
    }

    return _readExchangeRatesResult;
  }

  @override
  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates) async {
    writeExchangeRatesCallCount += 1;
    writtenExchangeRates = rates;

    if (writeError != null) {
      throw writeError!;
    }
  }
}
