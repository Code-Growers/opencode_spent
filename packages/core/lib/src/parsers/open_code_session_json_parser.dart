import 'dart:convert';

import '../info/openspent_info.dart';
import '../models/open_code_session.dart';

final class OpenCodeSessionJsonParser {
  const OpenCodeSessionJsonParser();

  List<OpenCodeSession> parse(String source) {
    final decoded = jsonDecode(source);
    final sessionNodes = _extractSessionNodes(decoded);

    return sessionNodes.map(_parseSessionNode).toList(growable: false);
  }

  List<Object?> _extractSessionNodes(Object? decoded) {
    if (decoded is List<Object?>) {
      return decoded;
    }

    if (decoded is Map<String, Object?>) {
      final sessions = decoded['sessions'];
      if (sessions is List<Object?>) {
        return sessions;
      }

      throw const FormatException(
        'Expected a top-level JSON list or an object with a sessions list.',
      );
    }

    throw const FormatException(
      'Expected a top-level JSON list or an object with a sessions list.',
    );
  }

  OpenCodeSession _parseSessionNode(Object? node) {
    if (node is! Map<String, Object?>) {
      throw const FormatException('Each session entry must be a JSON object.');
    }

    final metadata = _extractMetadata(node);
    final id = _readString(node, metadata, 'id');
    final createdAtValue = _readString(node, metadata, 'createdAt');

    if (id == null || id.isEmpty) {
      throw const FormatException('Each session must include a non-empty id.');
    }

    if (createdAtValue == null || createdAtValue.isEmpty) {
      throw const FormatException(
        'Each session must include a non-empty createdAt value.',
      );
    }

    return OpenCodeSession(
      id: id,
      modelName: _readString(node, metadata, 'modelName'),
      inputTokens: _readInt(node, metadata, 'inputTokens'),
      outputTokens: _readInt(node, metadata, 'outputTokens'),
      totalCostUsd: _readDouble(node, metadata, 'totalCostUsd'),
      createdAt: _parseCreatedAt(createdAtValue),
      subagentCategory: _sanitizeSubagentCategory(
        _readString(node, metadata, 'subagentCategory'),
      ),
    );
  }

  Map<String, Object?> _extractMetadata(Map<String, Object?> node) {
    final metadata = node['metadata'];
    if (metadata == null) {
      return const <String, Object?>{};
    }

    if (metadata is Map<String, Object?>) {
      return metadata;
    }

    throw const FormatException('Session metadata must be a JSON object.');
  }

  String? _readString(
    Map<String, Object?> node,
    Map<String, Object?> metadata,
    String key,
  ) {
    final value = node[key] ?? metadata[key];
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    throw FormatException('Expected $key to be a string.');
  }

  int? _readInt(
    Map<String, Object?> node,
    Map<String, Object?> metadata,
    String key,
  ) {
    final value = node[key] ?? metadata[key];
    if (value == null) {
      return null;
    }

    if (value is int) {
      if (value < 0) {
        throw FormatException('Expected $key to be a non-negative integer.');
      }

      return value;
    }

    if (value is num) {
      if (value == value.roundToDouble()) {
        final integerValue = value.toInt();
        if (integerValue < 0) {
          throw FormatException('Expected $key to be a non-negative integer.');
        }

        return integerValue;
      }
    }

    if (value is String) {
      final parsed = int.tryParse(value) ??
          (throw FormatException('Expected $key to be an integer.'));
      if (parsed < 0) {
        throw FormatException('Expected $key to be a non-negative integer.');
      }

      return parsed;
    }

    throw FormatException('Expected $key to be an integer.');
  }

  double? _readDouble(
    Map<String, Object?> node,
    Map<String, Object?> metadata,
    String key,
  ) {
    final value = node[key] ?? metadata[key];
    if (value == null) {
      return null;
    }

    if (value is num) {
      final parsed = value.toDouble();
      if (!parsed.isFinite || parsed < 0) {
        throw FormatException('Expected $key to be a non-negative number.');
      }

      return parsed;
    }

    if (value is String) {
      final parsed = double.tryParse(value) ??
          (throw FormatException('Expected $key to be numeric.'));
      if (!parsed.isFinite || parsed < 0) {
        throw FormatException('Expected $key to be a non-negative number.');
      }

      return parsed;
    }

    throw FormatException('Expected $key to be numeric.');
  }

  DateTime _parseCreatedAt(String value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?(?: ?(Z|[+-]\d{2}:?\d{2}))?)?$',
    ).firstMatch(value);

    if (match == null) {
      throw FormatException('Invalid createdAt value: $value');
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    if (!_isValidCalendarDate(year, month, day)) {
      throw FormatException('Invalid createdAt value: $value');
    }

    final hour = match.group(4) == null ? null : int.parse(match.group(4)!);
    final minute = match.group(5) == null ? null : int.parse(match.group(5)!);
    final second = match.group(6) == null ? 0 : int.parse(match.group(6)!);

    if (hour != null && (hour < 0 || hour > 23)) {
      throw FormatException('Invalid createdAt value: $value');
    }

    if (minute != null && (minute < 0 || minute > 59)) {
      throw FormatException('Invalid createdAt value: $value');
    }

    if (second < 0 || second > 59) {
      throw FormatException('Invalid createdAt value: $value');
    }

    final offset = match.group(8);
    if (offset != null && offset != 'Z') {
      final offsetMatch =
          RegExp(r'^([+-])(\d{2}):?(\d{2})$').firstMatch(offset);
      if (offsetMatch == null) {
        throw FormatException('Invalid createdAt value: $value');
      }

      final offsetHours = int.parse(offsetMatch.group(2)!);
      final offsetMinutes = int.parse(offsetMatch.group(3)!);
      if (offsetHours > 23 || offsetMinutes > 59) {
        throw FormatException('Invalid createdAt value: $value');
      }
    }

    final createdAt = DateTime.tryParse(value);
    if (createdAt == null) {
      throw FormatException('Invalid createdAt value: $value');
    }

    return createdAt.toUtc();
  }

  String? _sanitizeSubagentCategory(String? value) {
    if (value == null) {
      return null;
    }

    return OpenSpentInfo.supportedSubagentCategories.contains(value)
        ? value
        : null;
  }
}

bool _isValidCalendarDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1) {
    return false;
  }

  final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
  return day <= lastDayOfMonth;
}
