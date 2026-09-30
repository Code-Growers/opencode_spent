import 'harness_usage.dart';

final class LocalUsageSourceStatus {
  const LocalUsageSourceStatus({
    required this.harness,
    required this.connected,
    this.lastRefresh,
    this.sessions = 0,
    this.skippedRecords = 0,
    this.failedFiles = 0,
    this.unavailable = false,
  });
  final UsageHarness harness;
  final bool connected, unavailable;
  final DateTime? lastRefresh;
  final int sessions, skippedRecords, failedFiles;
}

abstract interface class LocalUsageSources {
  Future<List<LocalUsageSourceStatus>> statuses();
  Future<bool> connect(UsageHarness harness, {String? directory});
  Future<void> disconnect(UsageHarness harness);
  Future<void> refresh({UsageHarness? harness});
}
