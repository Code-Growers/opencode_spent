import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _dashboardDateTimePattern = 'dd.MM.yyyy HH:mm';

final RegExp _isoDateTimePattern = RegExp(
  r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z',
);

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();

DateFormat _dashboardDateFormat(BuildContext context) {
  return DateFormat(_dashboardDateTimePattern, _locale(context));
}

extension DashboardDateTimeFormatting on DateTime {
  String formatDashboardDateTime(BuildContext context) {
    return _dashboardDateFormat(context).format(toLocal());
  }

  String formatDashboardUtcDay(BuildContext context) {
    final utc = toUtc();
    final canonicalUtcDay = DateTime.utc(utc.year, utc.month, utc.day);
    return _dashboardDateFormat(context).format(canonicalUtcDay);
  }
}

String formatDashboardUtcDayIsoStrings(BuildContext context, String text) {
  return text.replaceAllMapped(_isoDateTimePattern, (match) {
    final value = DateTime.tryParse(match.group(0)!);
    if (value == null) {
      return match.group(0)!;
    }

    return value.formatDashboardUtcDay(context);
  });
}
