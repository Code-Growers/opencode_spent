import 'dart:typed_data';

import 'package:openspent_core/openspent_core.dart';

Future<List<OpenCodeSession>> readUploadedOpenCodeSessions(
  Uint8List databaseBytes, {
  void Function()? onWillAttemptDatabaseOpen,
}) async {
  onWillAttemptDatabaseOpen?.call();
  throw UnsupportedError(
    'Uploaded SQLite byte import is only available on web.',
  );
}
