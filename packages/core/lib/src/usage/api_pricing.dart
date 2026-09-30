import 'harness_usage.dart';

final class ApiRates {
  ApiRates({
    required this.input,
    required this.output,
    this.cachedInput,
    this.cacheWrite,
    this.cacheWrite1h,
    this.longContextThreshold,
    this.longContextRates,
  }) {
    for (final rate in [input, output, cachedInput, cacheWrite, cacheWrite1h]) {
      if (rate != null && (!rate.isFinite || rate < 0)) {
        throw const FormatException('Rates must be finite and nonnegative.');
      }
    }
  }
  final double input, output;
  final double? cachedInput, cacheWrite, cacheWrite1h;
  final int? longContextThreshold;
  final ApiRates? longContextRates;
  Map<String, Object?> toJson() => {
    'input': input,
    'output': output,
    'cachedInput': cachedInput,
    'cacheWrite': cacheWrite,
    'cacheWrite1h': cacheWrite1h,
  };
  factory ApiRates.fromJson(Map<String, dynamic> j) => ApiRates(
    input: (j['input'] as num).toDouble(),
    output: (j['output'] as num).toDouble(),
    cachedInput: (j['cachedInput'] as num?)?.toDouble(),
    cacheWrite: (j['cacheWrite'] as num?)?.toDouble(),
    cacheWrite1h: (j['cacheWrite1h'] as num?)?.toDouble(),
  );
}

final class ApiEstimate {
  const ApiEstimate(
    this.usd, {
    this.custom = false,
    this.assumedShortContext = false,
    this.assumedCacheDuration = false,
  });
  final double? usd;
  final bool custom, assumedShortContext, assumedCacheDuration;
}

final class PricingConfig {
  PricingConfig({
    Map<String, ApiRates> overrides = const {},
    Map<String, String> mappings = const {},
  }) : overrides = Map.unmodifiable(overrides),
       mappings = Map.unmodifiable(mappings);
  final Map<String, ApiRates> overrides;
  final Map<String, String> mappings;
  static String key(String provider, String model) => '$provider/$model';
  Map<String, Object?> toJson() => {
    'overrides': overrides.map((k, v) => MapEntry(k, v.toJson())),
    'mappings': mappings,
  };
  factory PricingConfig.fromJson(Map<String, dynamic> j) => PricingConfig(
    overrides: (j['overrides'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, ApiRates.fromJson(v as Map<String, dynamic>)),
    ),
    mappings: (j['mappings'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as String),
    ),
  );

  ApiEstimate estimate(UsageEvent event) {
    if (event.model == null) return const ApiEstimate(null);
    final originalKey = key(event.provider, event.model!);
    final mappedKey = mappings[originalKey] ?? originalKey;
    var rate =
        overrides[originalKey] ??
        overrides[mappedKey] ??
        ApiPriceCatalog.rates[mappedKey];
    final custom =
        overrides.containsKey(originalKey) ||
        overrides.containsKey(mappedKey) ||
        mappings.containsKey(originalKey);
    if (rate == null) return ApiEstimate(null, custom: custom);
    final assumedContext =
        rate.longContextRates != null && event.contextInputTokens == null;
    if (rate.longContextThreshold != null &&
        event.contextInputTokens != null &&
        event.contextInputTokens! > rate.longContextThreshold!) {
      rate = rate.longContextRates!;
    }
    final u = event.tokens;
    if (u.input == null || u.output == null) {
      return ApiEstimate(null, custom: custom);
    }
    // Missing cache counts cannot safely be treated as uncached input.
    if (u.cachedInput == null || u.cacheWrite == null) {
      return ApiEstimate(null, custom: custom);
    }
    final reads = u.cachedInput!;
    final writes = u.cacheWrite!;
    if (reads + writes > u.input! || (u.reasoning ?? 0) > u.output!) {
      return ApiEstimate(null, custom: custom);
    }
    if ((reads > 0 && rate.cachedInput == null) ||
        (writes > 0 && rate.cacheWrite == null)) {
      return ApiEstimate(null, custom: custom);
    }
    final oneHour = u.cacheWrite1h ?? 0;
    final fiveMinute = u.cacheWrite5m ?? 0;
    if (oneHour + fiveMinute > writes ||
        (oneHour > 0 && rate.cacheWrite1h == null)) {
      return ApiEstimate(null, custom: custom);
    }
    final usd =
        ((u.input! - reads - writes) * rate.input +
            u.output! * rate.output +
            reads * (rate.cachedInput ?? 0) +
            (writes - oneHour) * (rate.cacheWrite ?? 0) +
            oneHour * (rate.cacheWrite1h ?? 0)) /
        1000000;
    return ApiEstimate(
      usd,
      custom: custom,
      assumedShortContext: assumedContext,
      assumedCacheDuration:
          event.provider == 'anthropic' && writes > fiveMinute + oneHour,
    );
  }
}

abstract interface class PricingRepository {
  Future<PricingConfig> readPricing();
  Future<void> writePricing(PricingConfig config);
}

/// Offline standard API token rates, USD per million tokens.
/// Changes to this snapshot are explicit; usage never leaves the machine.
final class ApiPriceCatalog {
  static const version = '2026-09-30.2';
  static const verifiedOn = '2026-09-30';
  static const openAiSource = 'https://developers.openai.com/api/docs/pricing';
  static const anthropicSource =
      'https://platform.claude.com/docs/en/about-claude/pricing';
  static const additionalSources = [
    'https://developers.openai.com/api/docs/models/gpt-5.6-terra',
    'https://developers.openai.com/api/docs/models/gpt-5.6-luna',
  ];
  static final rates = Map<String, ApiRates>.unmodifiable({
    'openai/gpt-5.6-terra': ApiRates(
      input: 2,
      output: 12,
      cachedInput: 0.2,
      cacheWrite: 2.5,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: 4,
        output: 18.0,
        cachedInput: 0.4,
        cacheWrite: 5.0,
      ),
    ),
    'openai/gpt-5.6-luna': ApiRates(
      input: 0.2,
      output: 1.2,
      cachedInput: 0.02,
      cacheWrite: 0.25,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: 0.4,
        output: 1.7999999999999998,
        cachedInput: 0.04,
        cacheWrite: 0.5,
      ),
    ),
    'openai/gpt-5.6-sol': ApiRates(
      input: 4,
      output: 20,
      cachedInput: .4,
      cacheWrite: 5,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: 8,
        output: 30,
        cachedInput: .8,
        cacheWrite: 10,
      ),
    ),
    'openai/gpt-6-sol': ApiRates(
      input: 2,
      output: 10,
      cachedInput: .2,
      cacheWrite: 2.5,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: 4,
        output: 15,
        cachedInput: .4,
        cacheWrite: 5,
      ),
    ),
    'openai/gpt-6.1-sol': ApiRates(
      input: 2,
      output: 10,
      cachedInput: .1,
      cacheWrite: 2.5,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: 4,
        output: 15,
        cachedInput: .2,
        cacheWrite: 5,
      ),
    ),
    'openai/gpt-6-astra': ApiRates(
      input: 10,
      output: 50,
      cachedInput: 1,
      cacheWrite: 12.5,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: 20,
        output: 75,
        cachedInput: 2,
        cacheWrite: 25,
      ),
    ),
    'openai/gpt-6-luna': ApiRates(
      input: .1,
      output: .5,
      cachedInput: .01,
      cacheWrite: .125,
      longContextThreshold: 272000,
      longContextRates: ApiRates(
        input: .2,
        output: .75,
        cachedInput: .02,
        cacheWrite: .25,
      ),
    ),
    'openai/gpt-5.3-codex': ApiRates(
      input: 1.75,
      output: 14,
      cachedInput: .175,
    ),
    'anthropic/claude-opus-5-5': ApiRates(
      input: 4,
      output: 20,
      cachedInput: .2,
      cacheWrite: 5,
      cacheWrite1h: 8,
    ),
    'anthropic/claude-sonnet-5-5': ApiRates(
      input: 2,
      output: 10,
      cachedInput: .2,
      cacheWrite: 2.5,
      cacheWrite1h: 4,
    ),
    'anthropic/claude-opus-5': ApiRates(
      input: 5,
      output: 25,
      cachedInput: 0.5,
      cacheWrite: 6.25,
      cacheWrite1h: 10,
    ),
    'anthropic/claude-opus-4-8': ApiRates(
      input: 5,
      output: 25,
      cachedInput: 0.5,
      cacheWrite: 6.25,
      cacheWrite1h: 10,
    ),
    'anthropic/claude-fable-5': ApiRates(
      input: 10,
      output: 50,
      cachedInput: 1,
      cacheWrite: 12.5,
      cacheWrite1h: 20,
    ),
    'anthropic/claude-fable-5-1': ApiRates(
      input: 10,
      output: 50,
      cachedInput: 0.25,
      cacheWrite: 12.5,
      cacheWrite1h: 20,
    ),
    'anthropic/claude-sonnet-5': ApiRates(
      input: 2,
      output: 10,
      cachedInput: 0.2,
      cacheWrite: 2.5,
      cacheWrite1h: 4,
    ),
    'anthropic/claude-opus-4-6': ApiRates(
      input: 5,
      output: 25,
      cachedInput: .5,
      cacheWrite: 6.25,
      cacheWrite1h: 10,
    ),
    'anthropic/claude-sonnet-4-6': ApiRates(
      input: 3,
      output: 15,
      cachedInput: .3,
      cacheWrite: 3.75,
      cacheWrite1h: 6,
    ),
    'anthropic/claude-haiku-4-5': ApiRates(
      input: 1,
      output: 5,
      cachedInput: .1,
      cacheWrite: 1.25,
      cacheWrite1h: 2,
    ),
    'anthropic/claude-haiku-4-5-20251001': ApiRates(
      input: 1,
      output: 5,
      cachedInput: .1,
      cacheWrite: 1.25,
      cacheWrite1h: 2,
    ),
  });
}

final class HarnessUsageSummary {
  HarnessUsageSummary({
    required this.harness,
    required this.tokens,
    required this.eventCount,
    required this.pricedEventCount,
    required this.estimatedUsd,
    this.customPriceCount = 0,
    this.assumptionCount = 0,
  });
  final UsageHarness harness;
  final TokenUsage tokens;
  final int eventCount, pricedEventCount, customPriceCount, assumptionCount;
  final double? estimatedUsd;
  @override
  bool operator ==(Object other) =>
      other is HarnessUsageSummary &&
      harness == other.harness &&
      tokens == other.tokens &&
      eventCount == other.eventCount &&
      pricedEventCount == other.pricedEventCount &&
      estimatedUsd == other.estimatedUsd &&
      customPriceCount == other.customPriceCount &&
      assumptionCount == other.assumptionCount;
  @override
  int get hashCode => Object.hash(
    harness,
    tokens,
    eventCount,
    pricedEventCount,
    estimatedUsd,
    customPriceCount,
    assumptionCount,
  );
}
