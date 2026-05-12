import '../repositories/exchange_rate_repository.dart';

final class ExchangeRateSyncService {
  const ExchangeRateSyncService({
    required this.remoteRepository,
    required this.localRepository,
  });

  final ExchangeRateRepository remoteRepository;
  final ExchangeRateRepository localRepository;

  Future<void> syncExchangeRatesForDate(DateTime date) async {
    final rates = await remoteRepository.readExchangeRatesForDate(date);
    await localRepository.writeExchangeRates(rates, effectiveDate: date);
  }
}
