import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:openspent_core/openspent_core.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../../app/dashboard_build_info.dart';
import 'dashboard_chip_button.dart';
import 'dashboard_surface.dart';

class DashboardShellHeader extends StatelessWidget {
  const DashboardShellHeader({
    super.key,
    required this.hasSettingsRoute,
    required this.onHelpPressed,
    required this.onSettingsPressed,
  });

  final bool hasSettingsRoute;
  final VoidCallback onHelpPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return DashboardSurface(
      key: const Key('dashboard-shell-header'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      backgroundColor: dashboardSurfaceElevatedColor,
      showGlow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dashboardAccentColor.withValues(alpha: 0.14),
              border: Border.all(
                color: dashboardAccentColor.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.query_stats,
              color: dashboardAccentSoftColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            OpenSpentInfo.productName.toUpperCase(),
            style: textTheme.headlineSmall?.copyWith(height: 1),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: dashboardStatusColor.withValues(alpha: 0.10),
              border: Border.all(
                color: dashboardStatusColor.withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.localLabel,
              style: textTheme.labelLarge?.copyWith(
                color: dashboardStatusColor,
                height: 1,
              ),
            ),
          ),
          const Spacer(),
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
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(14),
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
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(
              color: dashboardPrimaryTextColor,
              height: 1,
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

    return DashboardSurface(
      key: const Key('dashboard-shell-hero'),
      padding: const EdgeInsets.all(24),
      backgroundColor: dashboardSurfaceElevatedColor,
      showGlow: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;

          return Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: wide ? 3 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.heroEyebrow,
                      style: textTheme.labelLarge?.copyWith(
                        color: dashboardAccentSoftColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.heroTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 32,
                        letterSpacing: 0.4,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        l10n.heroDescription,
                        style: textTheme.bodyLarge?.copyWith(
                          color: dashboardSecondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 20),
              Wrap(
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
                    color: dashboardAccentSoftColor,
                  ),
                  _HeroMetric(
                    label: l10n.heroMetricFieldsLabel,
                    value: l10n.heroMetricFieldsValue,
                    color: dashboardSecondaryTextColor,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
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
  });

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

    return DashboardSurface(
      key: const Key('dashboard-shell-nav'),
      padding: const EdgeInsets.all(12),
      backgroundColor: dashboardSurfaceElevatedColor,
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            DashboardChipButton(
              key: const Key('dashboard-nav-metrics'),
              label: l10n.shellNavMetrics,
              isSelected: selectedIndex == 0,
              onTap: onMetricsNav,
            ),
            if (hasSessionsRoute)
              DashboardChipButton(
                key: const Key('dashboard-nav-sessions'),
                label: l10n.shellNavSessions,
                isSelected: selectedIndex == 1,
                onTap: onSessionsNav,
              ),
            if (hasExchangeRatesRoute)
              DashboardChipButton(
                key: const Key('dashboard-nav-exchange-rates'),
                label: l10n.shellNavExchangeRates,
                isSelected: selectedIndex == 2,
                onTap: onExchangeRatesNav,
              ),
            DashboardChipButton(
              key: const Key('dashboard-nav-state'),
              label: l10n.shellNavState,
              isSelected: selectedIndex == 3,
              onTap: onStateNav,
            ),
          ],
        ),
      ),
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
                width: 16,
                height: 16,
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
