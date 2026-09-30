import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';
import '../../l10n/app_localizations.dart';
import 'harness_labels.dart';

class HarnessFilter extends StatelessWidget {
  const HarnessFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final UsageHarness? selected;
  final ValueChanged<UsageHarness?> onSelected;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final harness in <UsageHarness?>[null, ...UsageHarness.values])
          OutlinedButton(
            key: Key('harness-${harness?.name ?? 'all'}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: selected == harness
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => onSelected(harness),
            child: Text(
              harness == null
                  ? AppLocalizations.of(context)!.usageHarnessAll
                  : harnessLabel(harness),
            ),
          ),
      ],
    ),
  );
}
