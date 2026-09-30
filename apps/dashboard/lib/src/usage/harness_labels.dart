import 'package:openspent_core/openspent_core.dart';

String harnessLabel(UsageHarness harness) => switch (harness) {
  UsageHarness.openCode => 'OpenCode',
  UsageHarness.claudeCode => 'Claude Code',
  UsageHarness.codex => 'Codex',
};
