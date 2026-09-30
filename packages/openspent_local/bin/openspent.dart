import 'dart:io';
import 'package:openspent_local/src/cli/spending_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await SpendingCliRunner().run(args);
}
