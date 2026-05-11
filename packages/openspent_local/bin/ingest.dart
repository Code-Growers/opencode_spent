import 'dart:io' as io;

import 'package:openspent_local/src/cli/ingest_cli.dart';

Future<void> main(List<String> args) async {
  io.exitCode = await const IngestCliRunner().run(args);
}
