// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_spent_local_database.dart';

// ignore_for_file: type=lint
class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, LocalExchangeRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveDateUtcMeta = const VerificationMeta(
    'effectiveDateUtc',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveDateUtc =
      GeneratedColumn<DateTime>(
        'effective_date_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceDateUtcMeta = const VerificationMeta(
    'sourceDateUtc',
  );
  @override
  late final GeneratedColumn<DateTime> sourceDateUtc =
      GeneratedColumn<DateTime>(
        'source_date_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _rateToCzkMeta = const VerificationMeta(
    'rateToCzk',
  );
  @override
  late final GeneratedColumn<double> rateToCzk = GeneratedColumn<double>(
    'rate_to_czk',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    currencyCode,
    effectiveDateUtc,
    sourceDateUtc,
    rateToCzk,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalExchangeRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('effective_date_utc')) {
      context.handle(
        _effectiveDateUtcMeta,
        effectiveDateUtc.isAcceptableOrUnknown(
          data['effective_date_utc']!,
          _effectiveDateUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveDateUtcMeta);
    }
    if (data.containsKey('source_date_utc')) {
      context.handle(
        _sourceDateUtcMeta,
        sourceDateUtc.isAcceptableOrUnknown(
          data['source_date_utc']!,
          _sourceDateUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDateUtcMeta);
    }
    if (data.containsKey('rate_to_czk')) {
      context.handle(
        _rateToCzkMeta,
        rateToCzk.isAcceptableOrUnknown(data['rate_to_czk']!, _rateToCzkMeta),
      );
    } else if (isInserting) {
      context.missing(_rateToCzkMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {currencyCode, effectiveDateUtc};
  @override
  LocalExchangeRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalExchangeRateRow(
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      effectiveDateUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_date_utc'],
      )!,
      sourceDateUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_date_utc'],
      )!,
      rateToCzk: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate_to_czk'],
      )!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class LocalExchangeRateRow extends DataClass
    implements Insertable<LocalExchangeRateRow> {
  final String currencyCode;
  final DateTime effectiveDateUtc;
  final DateTime sourceDateUtc;
  final double rateToCzk;
  const LocalExchangeRateRow({
    required this.currencyCode,
    required this.effectiveDateUtc,
    required this.sourceDateUtc,
    required this.rateToCzk,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['currency_code'] = Variable<String>(currencyCode);
    map['effective_date_utc'] = Variable<DateTime>(effectiveDateUtc);
    map['source_date_utc'] = Variable<DateTime>(sourceDateUtc);
    map['rate_to_czk'] = Variable<double>(rateToCzk);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      currencyCode: Value(currencyCode),
      effectiveDateUtc: Value(effectiveDateUtc),
      sourceDateUtc: Value(sourceDateUtc),
      rateToCzk: Value(rateToCzk),
    );
  }

  factory LocalExchangeRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalExchangeRateRow(
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      effectiveDateUtc: serializer.fromJson<DateTime>(json['effectiveDateUtc']),
      sourceDateUtc: serializer.fromJson<DateTime>(json['sourceDateUtc']),
      rateToCzk: serializer.fromJson<double>(json['rateToCzk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'currencyCode': serializer.toJson<String>(currencyCode),
      'effectiveDateUtc': serializer.toJson<DateTime>(effectiveDateUtc),
      'sourceDateUtc': serializer.toJson<DateTime>(sourceDateUtc),
      'rateToCzk': serializer.toJson<double>(rateToCzk),
    };
  }

  LocalExchangeRateRow copyWith({
    String? currencyCode,
    DateTime? effectiveDateUtc,
    DateTime? sourceDateUtc,
    double? rateToCzk,
  }) => LocalExchangeRateRow(
    currencyCode: currencyCode ?? this.currencyCode,
    effectiveDateUtc: effectiveDateUtc ?? this.effectiveDateUtc,
    sourceDateUtc: sourceDateUtc ?? this.sourceDateUtc,
    rateToCzk: rateToCzk ?? this.rateToCzk,
  );
  LocalExchangeRateRow copyWithCompanion(ExchangeRatesCompanion data) {
    return LocalExchangeRateRow(
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      effectiveDateUtc: data.effectiveDateUtc.present
          ? data.effectiveDateUtc.value
          : this.effectiveDateUtc,
      sourceDateUtc: data.sourceDateUtc.present
          ? data.sourceDateUtc.value
          : this.sourceDateUtc,
      rateToCzk: data.rateToCzk.present ? data.rateToCzk.value : this.rateToCzk,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalExchangeRateRow(')
          ..write('currencyCode: $currencyCode, ')
          ..write('effectiveDateUtc: $effectiveDateUtc, ')
          ..write('sourceDateUtc: $sourceDateUtc, ')
          ..write('rateToCzk: $rateToCzk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(currencyCode, effectiveDateUtc, sourceDateUtc, rateToCzk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalExchangeRateRow &&
          other.currencyCode == this.currencyCode &&
          other.effectiveDateUtc == this.effectiveDateUtc &&
          other.sourceDateUtc == this.sourceDateUtc &&
          other.rateToCzk == this.rateToCzk);
}

class ExchangeRatesCompanion extends UpdateCompanion<LocalExchangeRateRow> {
  final Value<String> currencyCode;
  final Value<DateTime> effectiveDateUtc;
  final Value<DateTime> sourceDateUtc;
  final Value<double> rateToCzk;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.currencyCode = const Value.absent(),
    this.effectiveDateUtc = const Value.absent(),
    this.sourceDateUtc = const Value.absent(),
    this.rateToCzk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String currencyCode,
    required DateTime effectiveDateUtc,
    required DateTime sourceDateUtc,
    required double rateToCzk,
    this.rowid = const Value.absent(),
  }) : currencyCode = Value(currencyCode),
       effectiveDateUtc = Value(effectiveDateUtc),
       sourceDateUtc = Value(sourceDateUtc),
       rateToCzk = Value(rateToCzk);
  static Insertable<LocalExchangeRateRow> custom({
    Expression<String>? currencyCode,
    Expression<DateTime>? effectiveDateUtc,
    Expression<DateTime>? sourceDateUtc,
    Expression<double>? rateToCzk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (currencyCode != null) 'currency_code': currencyCode,
      if (effectiveDateUtc != null) 'effective_date_utc': effectiveDateUtc,
      if (sourceDateUtc != null) 'source_date_utc': sourceDateUtc,
      if (rateToCzk != null) 'rate_to_czk': rateToCzk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<String>? currencyCode,
    Value<DateTime>? effectiveDateUtc,
    Value<DateTime>? sourceDateUtc,
    Value<double>? rateToCzk,
    Value<int>? rowid,
  }) {
    return ExchangeRatesCompanion(
      currencyCode: currencyCode ?? this.currencyCode,
      effectiveDateUtc: effectiveDateUtc ?? this.effectiveDateUtc,
      sourceDateUtc: sourceDateUtc ?? this.sourceDateUtc,
      rateToCzk: rateToCzk ?? this.rateToCzk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (effectiveDateUtc.present) {
      map['effective_date_utc'] = Variable<DateTime>(effectiveDateUtc.value);
    }
    if (sourceDateUtc.present) {
      map['source_date_utc'] = Variable<DateTime>(sourceDateUtc.value);
    }
    if (rateToCzk.present) {
      map['rate_to_czk'] = Variable<double>(rateToCzk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('currencyCode: $currencyCode, ')
          ..write('effectiveDateUtc: $effectiveDateUtc, ')
          ..write('sourceDateUtc: $sourceDateUtc, ')
          ..write('rateToCzk: $rateToCzk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OpenCodeSessionsTable extends OpenCodeSessions
    with TableInfo<$OpenCodeSessionsTable, LocalOpenCodeSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpenCodeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCostUsdMeta = const VerificationMeta(
    'totalCostUsd',
  );
  @override
  late final GeneratedColumn<double> totalCostUsd = GeneratedColumn<double>(
    'total_cost_usd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestCountMeta = const VerificationMeta(
    'requestCount',
  );
  @override
  late final GeneratedColumn<int> requestCount = GeneratedColumn<int>(
    'request_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolCallCountMeta = const VerificationMeta(
    'toolCallCount',
  );
  @override
  late final GeneratedColumn<int> toolCallCount = GeneratedColumn<int>(
    'tool_call_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responseCountMeta = const VerificationMeta(
    'responseCount',
  );
  @override
  late final GeneratedColumn<int> responseCount = GeneratedColumn<int>(
    'response_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalResponseTimeMsMeta =
      const VerificationMeta('totalResponseTimeMs');
  @override
  late final GeneratedColumn<int> totalResponseTimeMs = GeneratedColumn<int>(
    'total_response_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subagentCategoryMeta = const VerificationMeta(
    'subagentCategory',
  );
  @override
  late final GeneratedColumn<String> subagentCategory = GeneratedColumn<String>(
    'subagent_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usageSlicesJsonMeta = const VerificationMeta(
    'usageSlicesJson',
  );
  @override
  late final GeneratedColumn<String> usageSlicesJson = GeneratedColumn<String>(
    'usage_slices_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtc,
    provider,
    modelName,
    inputTokens,
    outputTokens,
    totalCostUsd,
    requestCount,
    toolCallCount,
    responseCount,
    totalResponseTimeMs,
    subagentCategory,
    usageSlicesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'open_code_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOpenCodeSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('total_cost_usd')) {
      context.handle(
        _totalCostUsdMeta,
        totalCostUsd.isAcceptableOrUnknown(
          data['total_cost_usd']!,
          _totalCostUsdMeta,
        ),
      );
    }
    if (data.containsKey('request_count')) {
      context.handle(
        _requestCountMeta,
        requestCount.isAcceptableOrUnknown(
          data['request_count']!,
          _requestCountMeta,
        ),
      );
    }
    if (data.containsKey('tool_call_count')) {
      context.handle(
        _toolCallCountMeta,
        toolCallCount.isAcceptableOrUnknown(
          data['tool_call_count']!,
          _toolCallCountMeta,
        ),
      );
    }
    if (data.containsKey('response_count')) {
      context.handle(
        _responseCountMeta,
        responseCount.isAcceptableOrUnknown(
          data['response_count']!,
          _responseCountMeta,
        ),
      );
    }
    if (data.containsKey('total_response_time_ms')) {
      context.handle(
        _totalResponseTimeMsMeta,
        totalResponseTimeMs.isAcceptableOrUnknown(
          data['total_response_time_ms']!,
          _totalResponseTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('subagent_category')) {
      context.handle(
        _subagentCategoryMeta,
        subagentCategory.isAcceptableOrUnknown(
          data['subagent_category']!,
          _subagentCategoryMeta,
        ),
      );
    }
    if (data.containsKey('usage_slices_json')) {
      context.handle(
        _usageSlicesJsonMeta,
        usageSlicesJson.isAcceptableOrUnknown(
          data['usage_slices_json']!,
          _usageSlicesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOpenCodeSessionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOpenCodeSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      ),
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      ),
      totalCostUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_cost_usd'],
      ),
      requestCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}request_count'],
      ),
      toolCallCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tool_call_count'],
      ),
      responseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_count'],
      ),
      totalResponseTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_response_time_ms'],
      ),
      subagentCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subagent_category'],
      ),
      usageSlicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage_slices_json'],
      ),
    );
  }

  @override
  $OpenCodeSessionsTable createAlias(String alias) {
    return $OpenCodeSessionsTable(attachedDatabase, alias);
  }
}

class LocalOpenCodeSessionRow extends DataClass
    implements Insertable<LocalOpenCodeSessionRow> {
  final String id;
  final DateTime createdAtUtc;
  final String? provider;
  final String? modelName;
  final int? inputTokens;
  final int? outputTokens;
  final double? totalCostUsd;
  final int? requestCount;
  final int? toolCallCount;
  final int? responseCount;
  final int? totalResponseTimeMs;
  final String? subagentCategory;
  final String? usageSlicesJson;
  const LocalOpenCodeSessionRow({
    required this.id,
    required this.createdAtUtc,
    this.provider,
    this.modelName,
    this.inputTokens,
    this.outputTokens,
    this.totalCostUsd,
    this.requestCount,
    this.toolCallCount,
    this.responseCount,
    this.totalResponseTimeMs,
    this.subagentCategory,
    this.usageSlicesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || inputTokens != null) {
      map['input_tokens'] = Variable<int>(inputTokens);
    }
    if (!nullToAbsent || outputTokens != null) {
      map['output_tokens'] = Variable<int>(outputTokens);
    }
    if (!nullToAbsent || totalCostUsd != null) {
      map['total_cost_usd'] = Variable<double>(totalCostUsd);
    }
    if (!nullToAbsent || requestCount != null) {
      map['request_count'] = Variable<int>(requestCount);
    }
    if (!nullToAbsent || toolCallCount != null) {
      map['tool_call_count'] = Variable<int>(toolCallCount);
    }
    if (!nullToAbsent || responseCount != null) {
      map['response_count'] = Variable<int>(responseCount);
    }
    if (!nullToAbsent || totalResponseTimeMs != null) {
      map['total_response_time_ms'] = Variable<int>(totalResponseTimeMs);
    }
    if (!nullToAbsent || subagentCategory != null) {
      map['subagent_category'] = Variable<String>(subagentCategory);
    }
    if (!nullToAbsent || usageSlicesJson != null) {
      map['usage_slices_json'] = Variable<String>(usageSlicesJson);
    }
    return map;
  }

  OpenCodeSessionsCompanion toCompanion(bool nullToAbsent) {
    return OpenCodeSessionsCompanion(
      id: Value(id),
      createdAtUtc: Value(createdAtUtc),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      inputTokens: inputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(inputTokens),
      outputTokens: outputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(outputTokens),
      totalCostUsd: totalCostUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCostUsd),
      requestCount: requestCount == null && nullToAbsent
          ? const Value.absent()
          : Value(requestCount),
      toolCallCount: toolCallCount == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallCount),
      responseCount: responseCount == null && nullToAbsent
          ? const Value.absent()
          : Value(responseCount),
      totalResponseTimeMs: totalResponseTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(totalResponseTimeMs),
      subagentCategory: subagentCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subagentCategory),
      usageSlicesJson: usageSlicesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(usageSlicesJson),
    );
  }

  factory LocalOpenCodeSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOpenCodeSessionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      provider: serializer.fromJson<String?>(json['provider']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      inputTokens: serializer.fromJson<int?>(json['inputTokens']),
      outputTokens: serializer.fromJson<int?>(json['outputTokens']),
      totalCostUsd: serializer.fromJson<double?>(json['totalCostUsd']),
      requestCount: serializer.fromJson<int?>(json['requestCount']),
      toolCallCount: serializer.fromJson<int?>(json['toolCallCount']),
      responseCount: serializer.fromJson<int?>(json['responseCount']),
      totalResponseTimeMs: serializer.fromJson<int?>(
        json['totalResponseTimeMs'],
      ),
      subagentCategory: serializer.fromJson<String?>(json['subagentCategory']),
      usageSlicesJson: serializer.fromJson<String?>(json['usageSlicesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'provider': serializer.toJson<String?>(provider),
      'modelName': serializer.toJson<String?>(modelName),
      'inputTokens': serializer.toJson<int?>(inputTokens),
      'outputTokens': serializer.toJson<int?>(outputTokens),
      'totalCostUsd': serializer.toJson<double?>(totalCostUsd),
      'requestCount': serializer.toJson<int?>(requestCount),
      'toolCallCount': serializer.toJson<int?>(toolCallCount),
      'responseCount': serializer.toJson<int?>(responseCount),
      'totalResponseTimeMs': serializer.toJson<int?>(totalResponseTimeMs),
      'subagentCategory': serializer.toJson<String?>(subagentCategory),
      'usageSlicesJson': serializer.toJson<String?>(usageSlicesJson),
    };
  }

  LocalOpenCodeSessionRow copyWith({
    String? id,
    DateTime? createdAtUtc,
    Value<String?> provider = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<int?> inputTokens = const Value.absent(),
    Value<int?> outputTokens = const Value.absent(),
    Value<double?> totalCostUsd = const Value.absent(),
    Value<int?> requestCount = const Value.absent(),
    Value<int?> toolCallCount = const Value.absent(),
    Value<int?> responseCount = const Value.absent(),
    Value<int?> totalResponseTimeMs = const Value.absent(),
    Value<String?> subagentCategory = const Value.absent(),
    Value<String?> usageSlicesJson = const Value.absent(),
  }) => LocalOpenCodeSessionRow(
    id: id ?? this.id,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    provider: provider.present ? provider.value : this.provider,
    modelName: modelName.present ? modelName.value : this.modelName,
    inputTokens: inputTokens.present ? inputTokens.value : this.inputTokens,
    outputTokens: outputTokens.present ? outputTokens.value : this.outputTokens,
    totalCostUsd: totalCostUsd.present ? totalCostUsd.value : this.totalCostUsd,
    requestCount: requestCount.present ? requestCount.value : this.requestCount,
    toolCallCount: toolCallCount.present
        ? toolCallCount.value
        : this.toolCallCount,
    responseCount: responseCount.present
        ? responseCount.value
        : this.responseCount,
    totalResponseTimeMs: totalResponseTimeMs.present
        ? totalResponseTimeMs.value
        : this.totalResponseTimeMs,
    subagentCategory: subagentCategory.present
        ? subagentCategory.value
        : this.subagentCategory,
    usageSlicesJson: usageSlicesJson.present
        ? usageSlicesJson.value
        : this.usageSlicesJson,
  );
  LocalOpenCodeSessionRow copyWithCompanion(OpenCodeSessionsCompanion data) {
    return LocalOpenCodeSessionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      provider: data.provider.present ? data.provider.value : this.provider,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      totalCostUsd: data.totalCostUsd.present
          ? data.totalCostUsd.value
          : this.totalCostUsd,
      requestCount: data.requestCount.present
          ? data.requestCount.value
          : this.requestCount,
      toolCallCount: data.toolCallCount.present
          ? data.toolCallCount.value
          : this.toolCallCount,
      responseCount: data.responseCount.present
          ? data.responseCount.value
          : this.responseCount,
      totalResponseTimeMs: data.totalResponseTimeMs.present
          ? data.totalResponseTimeMs.value
          : this.totalResponseTimeMs,
      subagentCategory: data.subagentCategory.present
          ? data.subagentCategory.value
          : this.subagentCategory,
      usageSlicesJson: data.usageSlicesJson.present
          ? data.usageSlicesJson.value
          : this.usageSlicesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOpenCodeSessionRow(')
          ..write('id: $id, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('provider: $provider, ')
          ..write('modelName: $modelName, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('totalCostUsd: $totalCostUsd, ')
          ..write('requestCount: $requestCount, ')
          ..write('toolCallCount: $toolCallCount, ')
          ..write('responseCount: $responseCount, ')
          ..write('totalResponseTimeMs: $totalResponseTimeMs, ')
          ..write('subagentCategory: $subagentCategory, ')
          ..write('usageSlicesJson: $usageSlicesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAtUtc,
    provider,
    modelName,
    inputTokens,
    outputTokens,
    totalCostUsd,
    requestCount,
    toolCallCount,
    responseCount,
    totalResponseTimeMs,
    subagentCategory,
    usageSlicesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOpenCodeSessionRow &&
          other.id == this.id &&
          other.createdAtUtc == this.createdAtUtc &&
          other.provider == this.provider &&
          other.modelName == this.modelName &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.totalCostUsd == this.totalCostUsd &&
          other.requestCount == this.requestCount &&
          other.toolCallCount == this.toolCallCount &&
          other.responseCount == this.responseCount &&
          other.totalResponseTimeMs == this.totalResponseTimeMs &&
          other.subagentCategory == this.subagentCategory &&
          other.usageSlicesJson == this.usageSlicesJson);
}

class OpenCodeSessionsCompanion
    extends UpdateCompanion<LocalOpenCodeSessionRow> {
  final Value<String> id;
  final Value<DateTime> createdAtUtc;
  final Value<String?> provider;
  final Value<String?> modelName;
  final Value<int?> inputTokens;
  final Value<int?> outputTokens;
  final Value<double?> totalCostUsd;
  final Value<int?> requestCount;
  final Value<int?> toolCallCount;
  final Value<int?> responseCount;
  final Value<int?> totalResponseTimeMs;
  final Value<String?> subagentCategory;
  final Value<String?> usageSlicesJson;
  final Value<int> rowid;
  const OpenCodeSessionsCompanion({
    this.id = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.provider = const Value.absent(),
    this.modelName = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.totalCostUsd = const Value.absent(),
    this.requestCount = const Value.absent(),
    this.toolCallCount = const Value.absent(),
    this.responseCount = const Value.absent(),
    this.totalResponseTimeMs = const Value.absent(),
    this.subagentCategory = const Value.absent(),
    this.usageSlicesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OpenCodeSessionsCompanion.insert({
    required String id,
    required DateTime createdAtUtc,
    this.provider = const Value.absent(),
    this.modelName = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.totalCostUsd = const Value.absent(),
    this.requestCount = const Value.absent(),
    this.toolCallCount = const Value.absent(),
    this.responseCount = const Value.absent(),
    this.totalResponseTimeMs = const Value.absent(),
    this.subagentCategory = const Value.absent(),
    this.usageSlicesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<LocalOpenCodeSessionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAtUtc,
    Expression<String>? provider,
    Expression<String>? modelName,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<double>? totalCostUsd,
    Expression<int>? requestCount,
    Expression<int>? toolCallCount,
    Expression<int>? responseCount,
    Expression<int>? totalResponseTimeMs,
    Expression<String>? subagentCategory,
    Expression<String>? usageSlicesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (provider != null) 'provider': provider,
      if (modelName != null) 'model_name': modelName,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (totalCostUsd != null) 'total_cost_usd': totalCostUsd,
      if (requestCount != null) 'request_count': requestCount,
      if (toolCallCount != null) 'tool_call_count': toolCallCount,
      if (responseCount != null) 'response_count': responseCount,
      if (totalResponseTimeMs != null)
        'total_response_time_ms': totalResponseTimeMs,
      if (subagentCategory != null) 'subagent_category': subagentCategory,
      if (usageSlicesJson != null) 'usage_slices_json': usageSlicesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OpenCodeSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAtUtc,
    Value<String?>? provider,
    Value<String?>? modelName,
    Value<int?>? inputTokens,
    Value<int?>? outputTokens,
    Value<double?>? totalCostUsd,
    Value<int?>? requestCount,
    Value<int?>? toolCallCount,
    Value<int?>? responseCount,
    Value<int?>? totalResponseTimeMs,
    Value<String?>? subagentCategory,
    Value<String?>? usageSlicesJson,
    Value<int>? rowid,
  }) {
    return OpenCodeSessionsCompanion(
      id: id ?? this.id,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalCostUsd: totalCostUsd ?? this.totalCostUsd,
      requestCount: requestCount ?? this.requestCount,
      toolCallCount: toolCallCount ?? this.toolCallCount,
      responseCount: responseCount ?? this.responseCount,
      totalResponseTimeMs: totalResponseTimeMs ?? this.totalResponseTimeMs,
      subagentCategory: subagentCategory ?? this.subagentCategory,
      usageSlicesJson: usageSlicesJson ?? this.usageSlicesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (totalCostUsd.present) {
      map['total_cost_usd'] = Variable<double>(totalCostUsd.value);
    }
    if (requestCount.present) {
      map['request_count'] = Variable<int>(requestCount.value);
    }
    if (toolCallCount.present) {
      map['tool_call_count'] = Variable<int>(toolCallCount.value);
    }
    if (responseCount.present) {
      map['response_count'] = Variable<int>(responseCount.value);
    }
    if (totalResponseTimeMs.present) {
      map['total_response_time_ms'] = Variable<int>(totalResponseTimeMs.value);
    }
    if (subagentCategory.present) {
      map['subagent_category'] = Variable<String>(subagentCategory.value);
    }
    if (usageSlicesJson.present) {
      map['usage_slices_json'] = Variable<String>(usageSlicesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OpenCodeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('provider: $provider, ')
          ..write('modelName: $modelName, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('totalCostUsd: $totalCostUsd, ')
          ..write('requestCount: $requestCount, ')
          ..write('toolCallCount: $toolCallCount, ')
          ..write('responseCount: $responseCount, ')
          ..write('totalResponseTimeMs: $totalResponseTimeMs, ')
          ..write('subagentCategory: $subagentCategory, ')
          ..write('usageSlicesJson: $usageSlicesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OpenSpentLocalDatabase extends GeneratedDatabase {
  _$OpenSpentLocalDatabase(QueryExecutor e) : super(e);
  $OpenSpentLocalDatabaseManager get managers =>
      $OpenSpentLocalDatabaseManager(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $OpenCodeSessionsTable openCodeSessions = $OpenCodeSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exchangeRates,
    openCodeSessions,
  ];
}

typedef $$ExchangeRatesTableCreateCompanionBuilder =
    ExchangeRatesCompanion Function({
      required String currencyCode,
      required DateTime effectiveDateUtc,
      required DateTime sourceDateUtc,
      required double rateToCzk,
      Value<int> rowid,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<String> currencyCode,
      Value<DateTime> effectiveDateUtc,
      Value<DateTime> sourceDateUtc,
      Value<double> rateToCzk,
      Value<int> rowid,
    });

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$OpenSpentLocalDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveDateUtc => $composableBuilder(
    column: $table.effectiveDateUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceDateUtc => $composableBuilder(
    column: $table.sourceDateUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rateToCzk => $composableBuilder(
    column: $table.rateToCzk,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$OpenSpentLocalDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveDateUtc => $composableBuilder(
    column: $table.effectiveDateUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceDateUtc => $composableBuilder(
    column: $table.sourceDateUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rateToCzk => $composableBuilder(
    column: $table.rateToCzk,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$OpenSpentLocalDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get effectiveDateUtc => $composableBuilder(
    column: $table.effectiveDateUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceDateUtc => $composableBuilder(
    column: $table.sourceDateUtc,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rateToCzk =>
      $composableBuilder(column: $table.rateToCzk, builder: (column) => column);
}

class $$ExchangeRatesTableTableManager
    extends
        RootTableManager<
          _$OpenSpentLocalDatabase,
          $ExchangeRatesTable,
          LocalExchangeRateRow,
          $$ExchangeRatesTableFilterComposer,
          $$ExchangeRatesTableOrderingComposer,
          $$ExchangeRatesTableAnnotationComposer,
          $$ExchangeRatesTableCreateCompanionBuilder,
          $$ExchangeRatesTableUpdateCompanionBuilder,
          (
            LocalExchangeRateRow,
            BaseReferences<
              _$OpenSpentLocalDatabase,
              $ExchangeRatesTable,
              LocalExchangeRateRow
            >,
          ),
          LocalExchangeRateRow,
          PrefetchHooks Function()
        > {
  $$ExchangeRatesTableTableManager(
    _$OpenSpentLocalDatabase db,
    $ExchangeRatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> effectiveDateUtc = const Value.absent(),
                Value<DateTime> sourceDateUtc = const Value.absent(),
                Value<double> rateToCzk = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion(
                currencyCode: currencyCode,
                effectiveDateUtc: effectiveDateUtc,
                sourceDateUtc: sourceDateUtc,
                rateToCzk: rateToCzk,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String currencyCode,
                required DateTime effectiveDateUtc,
                required DateTime sourceDateUtc,
                required double rateToCzk,
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion.insert(
                currencyCode: currencyCode,
                effectiveDateUtc: effectiveDateUtc,
                sourceDateUtc: sourceDateUtc,
                rateToCzk: rateToCzk,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExchangeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenSpentLocalDatabase,
      $ExchangeRatesTable,
      LocalExchangeRateRow,
      $$ExchangeRatesTableFilterComposer,
      $$ExchangeRatesTableOrderingComposer,
      $$ExchangeRatesTableAnnotationComposer,
      $$ExchangeRatesTableCreateCompanionBuilder,
      $$ExchangeRatesTableUpdateCompanionBuilder,
      (
        LocalExchangeRateRow,
        BaseReferences<
          _$OpenSpentLocalDatabase,
          $ExchangeRatesTable,
          LocalExchangeRateRow
        >,
      ),
      LocalExchangeRateRow,
      PrefetchHooks Function()
    >;
typedef $$OpenCodeSessionsTableCreateCompanionBuilder =
    OpenCodeSessionsCompanion Function({
      required String id,
      required DateTime createdAtUtc,
      Value<String?> provider,
      Value<String?> modelName,
      Value<int?> inputTokens,
      Value<int?> outputTokens,
      Value<double?> totalCostUsd,
      Value<int?> requestCount,
      Value<int?> toolCallCount,
      Value<int?> responseCount,
      Value<int?> totalResponseTimeMs,
      Value<String?> subagentCategory,
      Value<String?> usageSlicesJson,
      Value<int> rowid,
    });
typedef $$OpenCodeSessionsTableUpdateCompanionBuilder =
    OpenCodeSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAtUtc,
      Value<String?> provider,
      Value<String?> modelName,
      Value<int?> inputTokens,
      Value<int?> outputTokens,
      Value<double?> totalCostUsd,
      Value<int?> requestCount,
      Value<int?> toolCallCount,
      Value<int?> responseCount,
      Value<int?> totalResponseTimeMs,
      Value<String?> subagentCategory,
      Value<String?> usageSlicesJson,
      Value<int> rowid,
    });

class $$OpenCodeSessionsTableFilterComposer
    extends Composer<_$OpenSpentLocalDatabase, $OpenCodeSessionsTable> {
  $$OpenCodeSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCostUsd => $composableBuilder(
    column: $table.totalCostUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestCount => $composableBuilder(
    column: $table.requestCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toolCallCount => $composableBuilder(
    column: $table.toolCallCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseCount => $composableBuilder(
    column: $table.responseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalResponseTimeMs => $composableBuilder(
    column: $table.totalResponseTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subagentCategory => $composableBuilder(
    column: $table.subagentCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usageSlicesJson => $composableBuilder(
    column: $table.usageSlicesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OpenCodeSessionsTableOrderingComposer
    extends Composer<_$OpenSpentLocalDatabase, $OpenCodeSessionsTable> {
  $$OpenCodeSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCostUsd => $composableBuilder(
    column: $table.totalCostUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestCount => $composableBuilder(
    column: $table.requestCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toolCallCount => $composableBuilder(
    column: $table.toolCallCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseCount => $composableBuilder(
    column: $table.responseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalResponseTimeMs => $composableBuilder(
    column: $table.totalResponseTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subagentCategory => $composableBuilder(
    column: $table.subagentCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usageSlicesJson => $composableBuilder(
    column: $table.usageSlicesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OpenCodeSessionsTableAnnotationComposer
    extends Composer<_$OpenSpentLocalDatabase, $OpenCodeSessionsTable> {
  $$OpenCodeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCostUsd => $composableBuilder(
    column: $table.totalCostUsd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requestCount => $composableBuilder(
    column: $table.requestCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toolCallCount => $composableBuilder(
    column: $table.toolCallCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseCount => $composableBuilder(
    column: $table.responseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalResponseTimeMs => $composableBuilder(
    column: $table.totalResponseTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subagentCategory => $composableBuilder(
    column: $table.subagentCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usageSlicesJson => $composableBuilder(
    column: $table.usageSlicesJson,
    builder: (column) => column,
  );
}

class $$OpenCodeSessionsTableTableManager
    extends
        RootTableManager<
          _$OpenSpentLocalDatabase,
          $OpenCodeSessionsTable,
          LocalOpenCodeSessionRow,
          $$OpenCodeSessionsTableFilterComposer,
          $$OpenCodeSessionsTableOrderingComposer,
          $$OpenCodeSessionsTableAnnotationComposer,
          $$OpenCodeSessionsTableCreateCompanionBuilder,
          $$OpenCodeSessionsTableUpdateCompanionBuilder,
          (
            LocalOpenCodeSessionRow,
            BaseReferences<
              _$OpenSpentLocalDatabase,
              $OpenCodeSessionsTable,
              LocalOpenCodeSessionRow
            >,
          ),
          LocalOpenCodeSessionRow,
          PrefetchHooks Function()
        > {
  $$OpenCodeSessionsTableTableManager(
    _$OpenSpentLocalDatabase db,
    $OpenCodeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpenCodeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpenCodeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpenCodeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<int?> inputTokens = const Value.absent(),
                Value<int?> outputTokens = const Value.absent(),
                Value<double?> totalCostUsd = const Value.absent(),
                Value<int?> requestCount = const Value.absent(),
                Value<int?> toolCallCount = const Value.absent(),
                Value<int?> responseCount = const Value.absent(),
                Value<int?> totalResponseTimeMs = const Value.absent(),
                Value<String?> subagentCategory = const Value.absent(),
                Value<String?> usageSlicesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpenCodeSessionsCompanion(
                id: id,
                createdAtUtc: createdAtUtc,
                provider: provider,
                modelName: modelName,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                totalCostUsd: totalCostUsd,
                requestCount: requestCount,
                toolCallCount: toolCallCount,
                responseCount: responseCount,
                totalResponseTimeMs: totalResponseTimeMs,
                subagentCategory: subagentCategory,
                usageSlicesJson: usageSlicesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAtUtc,
                Value<String?> provider = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<int?> inputTokens = const Value.absent(),
                Value<int?> outputTokens = const Value.absent(),
                Value<double?> totalCostUsd = const Value.absent(),
                Value<int?> requestCount = const Value.absent(),
                Value<int?> toolCallCount = const Value.absent(),
                Value<int?> responseCount = const Value.absent(),
                Value<int?> totalResponseTimeMs = const Value.absent(),
                Value<String?> subagentCategory = const Value.absent(),
                Value<String?> usageSlicesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpenCodeSessionsCompanion.insert(
                id: id,
                createdAtUtc: createdAtUtc,
                provider: provider,
                modelName: modelName,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                totalCostUsd: totalCostUsd,
                requestCount: requestCount,
                toolCallCount: toolCallCount,
                responseCount: responseCount,
                totalResponseTimeMs: totalResponseTimeMs,
                subagentCategory: subagentCategory,
                usageSlicesJson: usageSlicesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OpenCodeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenSpentLocalDatabase,
      $OpenCodeSessionsTable,
      LocalOpenCodeSessionRow,
      $$OpenCodeSessionsTableFilterComposer,
      $$OpenCodeSessionsTableOrderingComposer,
      $$OpenCodeSessionsTableAnnotationComposer,
      $$OpenCodeSessionsTableCreateCompanionBuilder,
      $$OpenCodeSessionsTableUpdateCompanionBuilder,
      (
        LocalOpenCodeSessionRow,
        BaseReferences<
          _$OpenSpentLocalDatabase,
          $OpenCodeSessionsTable,
          LocalOpenCodeSessionRow
        >,
      ),
      LocalOpenCodeSessionRow,
      PrefetchHooks Function()
    >;

class $OpenSpentLocalDatabaseManager {
  final _$OpenSpentLocalDatabase _db;
  $OpenSpentLocalDatabaseManager(this._db);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$OpenCodeSessionsTableTableManager get openCodeSessions =>
      $$OpenCodeSessionsTableTableManager(_db, _db.openCodeSessions);
}
