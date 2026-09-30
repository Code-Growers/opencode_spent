import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:openspent_core/openspent_core.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../../app/dashboard_build_info.dart';
import 'dashboard_surface.dart';
import 'dashboard_chip_button.dart';

class DashboardShellHeader extends StatelessWidget {
  const DashboardShellHeader({
    super.key,
    required this.hasSettingsRoute,
    required this.onHelpPressed,
    required this.onSettingsPressed,
    this.isMockData = false,
    this.onModeChanged,
  });

  final bool hasSettingsRoute;
  final VoidCallback onHelpPressed;
  final VoidCallback onSettingsPressed;
  final bool isMockData;
  final VoidCallback? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return DashboardSurface(
      key: const Key('dashboard-shell-header'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 20,
        vertical: compact ? 12 : 16,
      ),
      backgroundColor: dashboardSurfaceElevatedColor,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                SvgPicture.asset(
                  'web/brand-symbol.svg',
                  width: compact ? 18 : 24,
                  height: compact ? 24 : 32,
                  colorFilter: const ColorFilter.mode(
                    dashboardPrimaryTextColor,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: compact ? 8 : 14),
                Flexible(
                  child: Text(
                    OpenSpentInfo.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.headlineSmall?.copyWith(
                      height: 1,
                      fontSize: compact ? 20 : null,
                    ),
                  ),
                ),
                if (MediaQuery.sizeOf(context).width >= 600) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: dashboardBorderColor),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      l10n.localLabel,
                      style: textTheme.labelLarge?.copyWith(
                        color: dashboardStatusColor,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onModeChanged != null) ...[
            Tooltip(
              message: isMockData ? l10n.mockDataNotice : l10n.realDataNotice,
              child: DashboardChipButton(
                key: const Key('header-data-mode'),
                label: compact
                    ? isMockData
                          ? l10n.dataModeMock
                          : l10n.dataModeReal
                    : isMockData
                    ? l10n.mockDataLabel
                    : l10n.realDataNotice,
                isSelected: isMockData,
                onTap: onModeChanged,
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            key: const Key('help-open-button'),
            onPressed: onHelpPressed,
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.helpDialogTitle,
          ),
          if (hasSettingsRoute) ...[
            const SizedBox(width: 8),
            IconButton(
              key: const Key('settings-open-button'),
              onPressed: onSettingsPressed,
              icon: const Icon(Icons.tune),
              tooltip: l10n.settingsTitle,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dashboardBorderColor),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: dashboardSecondaryTextColor,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: textTheme.labelLarge?.copyWith(
                color: dashboardPrimaryTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardShellHero extends StatelessWidget {
  const DashboardShellHero({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return CustomPaint(
      foregroundPainter: const _BrandFramePainter(),
      child: DashboardSurface(
        key: const Key('dashboard-shell-hero'),
        padding: const EdgeInsets.all(28),
        backgroundColor: dashboardBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.heroEyebrow,
                  style: textTheme.labelSmall?.copyWith(
                    color: dashboardSecondaryTextColor,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.heroTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontSize: wide ? 46 : 32,
                    fontWeight: FontWeight.w400,
                    color: dashboardAccentColor,
                    letterSpacing: -1.2,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Text(l10n.heroDescription, style: textTheme.bodyLarge),
                ),
              ],
            );
            final facts = Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HeroMetric(
                  label: l10n.heroMetricSyncLabel,
                  value: l10n.heroMetricSyncValue,
                  color: dashboardStatusColor,
                ),
                _HeroMetric(
                  label: l10n.heroMetricDataLabel,
                  value: l10n.heroMetricDataValue,
                  color: dashboardAccentColor,
                ),
                _HeroMetric(
                  label: l10n.heroMetricFieldsLabel,
                  value: l10n.heroMetricFieldsValue,
                  color: dashboardSecondaryTextColor,
                ),
              ],
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 24), facts],
              );
            }
            return Row(
              children: [
                Expanded(flex: 3, child: heading),
                const SizedBox(width: 40),
                Expanded(child: facts),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Registration marks echo the intersections in the Code Growers site frame.
class _BrandFramePainter extends CustomPainter {
  const _BrandFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dashboardSecondaryTextColor
      ..strokeWidth = 1;
    for (final point in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      canvas.drawLine(
        point - const Offset(4, 0),
        point + const Offset(4, 0),
        paint,
      );
      canvas.drawLine(
        point - const Offset(0, 4),
        point + const Offset(0, 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrandFramePainter oldDelegate) => false;
}

class DashboardShellNav extends StatelessWidget {
  const DashboardShellNav({
    super.key,
    required this.selectedIndex,
    required this.hasSessionsRoute,
    required this.hasExchangeRatesRoute,
    required this.onMetricsNav,
    required this.onSessionsNav,
    required this.onExchangeRatesNav,
    required this.onStateNav,
    this.vertical = false,
  });

  final bool vertical;
  final int selectedIndex;
  final bool hasSessionsRoute;
  final bool hasExchangeRatesRoute;
  final VoidCallback onMetricsNav;
  final VoidCallback onSessionsNav;
  final VoidCallback onExchangeRatesNav;
  final VoidCallback onStateNav;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final entries =
        <({String label, Key key, bool selected, VoidCallback onTap})>[
          (
            label: l10n.shellNavMetrics,
            key: const Key('dashboard-nav-metrics'),
            selected: selectedIndex == 0,
            onTap: onMetricsNav,
          ),
          if (hasSessionsRoute)
            (
              label: l10n.shellNavSessions,
              key: const Key('dashboard-nav-sessions'),
              selected: selectedIndex == 1,
              onTap: onSessionsNav,
            ),
          if (hasExchangeRatesRoute)
            (
              label: l10n.shellNavExchangeRates,
              key: const Key('dashboard-nav-exchange-rates'),
              selected: selectedIndex == 2,
              onTap: onExchangeRatesNav,
            ),
          (
            label: l10n.shellNavState,
            key: const Key('dashboard-nav-state'),
            selected: selectedIndex == 3,
            onTap: onStateNav,
          ),
        ];
    return LayoutBuilder(
      key: const Key('dashboard-shell-nav'),
      builder: (context, constraints) {
        final columns = vertical
            ? 1
            : constraints.maxWidth >= 640
            ? entries.length
            : 2;
        return Wrap(
          children: [
            for (var index = 0; index < entries.length; index++)
              SizedBox(
                width: constraints.maxWidth / columns,
                child: Semantics(
                  button: true,
                  selected: entries[index].selected,
                  child: Material(
                    color: entries[index].selected
                        ? dashboardSurfaceHighlightColor
                        : dashboardBackgroundColor,
                    child: InkWell(
                      key: entries[index].key,
                      onTap: entries[index].onTap,
                      hoverColor: dashboardAccentColor.withValues(alpha: 0.08),
                      focusColor: dashboardAccentColor.withValues(alpha: 0.2),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 58),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: entries[index].selected
                                  ? dashboardAccentColor
                                  : dashboardBorderColor,
                              width: entries[index].selected ? 2 : 1,
                            ),
                            bottom: const BorderSide(
                              color: dashboardBorderColor,
                            ),
                            left: const BorderSide(color: dashboardBorderColor),
                            right: const BorderSide(
                              color: dashboardBorderColor,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entries[index].label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: entries[index].selected
                                          ? dashboardAccentColor
                                          : dashboardPrimaryTextColor,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '0${index + 1}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: dashboardSecondaryTextColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class DashboardShellFooter extends StatelessWidget {
  const DashboardShellFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        key: const Key('dashboard-shell-footer'),
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              SvgPicture.asset(
                DashboardBuildInfo.dashboardLogoAssetPath,
                key: const Key('dashboard-shell-brand-logo'),
                width: 80,
                height: 27,
                colorFilter: const ColorFilter.mode(
                  dashboardSecondaryTextColor,
                  BlendMode.srcIn,
                ),
              ),
              Text(
                l10n.shellFooterDevelopedBy(
                  DashboardBuildInfo.dashboardCompanyName,
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: dashboardSecondaryTextColor,
                ),
              ),
            ],
          ),
          Text(
            l10n.shellFooterBuildVersion(
              DashboardBuildInfo.dashboardBuildVersion,
            ),
            key: const Key('dashboard-shell-build-version'),
            style: textTheme.bodySmall?.copyWith(
              color: dashboardSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
