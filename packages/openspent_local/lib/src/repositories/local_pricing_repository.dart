import 'dart:convert';
import 'package:openspent_core/openspent_core.dart';
import '../preferences/key_value_store.dart';

final class LocalPricingRepository implements PricingRepository {
  LocalPricingRepository(this._store);
  final KeyValueStore _store;
  static const storageKey = 'openspent.apiPricing.v1';
  @override
  Future<PricingConfig> readPricing() async {
    final raw = await _store.readString(storageKey);
    if (raw == null) return PricingConfig();
    try {
      return PricingConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PricingConfig();
    }
  }

  @override
  Future<void> writePricing(PricingConfig config) =>
      _store.writeString(storageKey, jsonEncode(config.toJson()));
}
