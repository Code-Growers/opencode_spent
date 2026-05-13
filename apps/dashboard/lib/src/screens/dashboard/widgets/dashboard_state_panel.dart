import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../../demo/dashboard_demo.dart';
import '../dashboard_shell_screen.dart' show ServerProbeState;
import 'dashboard_chip_button.dart';
import 'dashboard_surface.dart';
import 'dashboard_paired_row.dart';
import 'terminal_pane.dart';

class DashboardStatePanel extends StatelessWidget {
  const DashboardStatePanel({
    super.key,
    required this.isMockData,
    required this.settingsLoaded,
    required this.serverLabel,
    required this.probeState,
    required this.displayProbe,
    required this.demoModeController,
    required this.allowlistCount,
  });

  final bool isMockData;
  final bool settingsLoaded;
  final String serverLabel;
  final ServerProbeState probeState;
  final String displayProbe;
  final DemoModeController? demoModeController;
  final int allowlistCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wideLayout = constraints.maxWidth >= 680;
          final paneWidth = wideLayout
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (demoModeController != null) ...[
                Row(
                  children: [
                    Text(l10n.dataModeLabel, style: textTheme.bodyLarge),
                    const SizedBox(width: 16),
                    DashboardChipButton(
                      label: l10n.dataModeReal,
                      isSelected: !isMockData,
                      onTap: isMockData ? demoModeController!.toggle : null,
                    ),
                    const SizedBox(width: 8),
                    DashboardChipButton(
                      label: l10n.dataModeMock,
                      isSelected: isMockData,
                      onTap: !isMockData ? demoModeController!.toggle : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (wideLayout)
                DashboardPairedRow(
                  spacing: 16,
                  firstChild: TerminalPane(
                    key: const Key('dashboard-kpi-status'),
                    title: l10n.statusPaneTitle,
                    lines: [
                      l10n.statusLineReady(
                        settingsLoaded ? l10n.statusReady : l10n.statusLoading,
                      ),
                      l10n.statusLineMode(
                        isMockData
                            ? '${l10n.statusModeLocalCache}${l10n.statusModeMockSuffix}'
                            : l10n.statusModeLocalCache,
                      ),
                      l10n.statusLineServer(serverLabel),
                      l10n.statusLineProbe(displayProbe),
                    ],
                    lineStyles: [
                      null,
                      null,
                      null,
                      probeState == ServerProbeState.connected
                          ? textTheme.bodyLarge?.copyWith(
                              color: dashboardStatusColor,
                            )
                          : null,
                    ],
                  ),
                  secondChild: TerminalPane(
                    key: const Key('dashboard-kpi-privacy'),
                    title: l10n.privacyPaneTitle,
                    lines: [
                      l10n.privacyLinePrompts,
                      l10n.privacyLineToolOutput,
                      l10n.privacyLineErrors,
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: paneWidth,
                      child: TerminalPane(
                        title: l10n.statusPaneTitle,
                        lines: [
                          l10n.statusLineReady(
                            settingsLoaded
                                ? l10n.statusReady
                                : l10n.statusLoading,
                          ),
                          l10n.statusLineMode(
                            isMockData
                                ? '${l10n.statusModeLocalCache}${l10n.statusModeMockSuffix}'
                                : l10n.statusModeLocalCache,
                          ),
                          l10n.statusLineServer(serverLabel),
                          l10n.statusLineProbe(displayProbe),
                        ],
                        lineStyles: [
                          null,
                          null,
                          null,
                          probeState == ServerProbeState.connected
                              ? textTheme.bodyLarge?.copyWith(
                                  color: dashboardStatusColor,
                                )
                              : null,
                        ],
                      ),
                    ),
                    SizedBox(
                      width: paneWidth,
                      child: TerminalPane(
                        title: l10n.privacyPaneTitle,
                        lines: [
                          l10n.privacyLinePrompts,
                          l10n.privacyLineToolOutput,
                          l10n.privacyLineErrors,
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              DashboardSurface(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    l10n.persistedAllowlist(allowlistCount),
                    style: textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
