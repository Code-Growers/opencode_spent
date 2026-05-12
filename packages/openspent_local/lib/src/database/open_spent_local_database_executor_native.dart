import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

QueryExecutor createInMemoryOpenSpentLocalDatabaseExecutor() {
  return NativeDatabase.memory();
}

QueryExecutor createFileOpenSpentLocalDatabaseExecutor(String path) {
  return NativeDatabase.createInBackground(File(path));
}
