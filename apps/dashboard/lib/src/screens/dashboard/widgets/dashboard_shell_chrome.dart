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

    return Row(
      key: const Key('dashboard-shell-header'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '[ ${OpenSpentInfo.productName.toUpperCase()} ]',
          style: textTheme.headlineSmall?.copyWith(height: 1),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: dashboardBorderColor),
          ),
          child: Text(
            l10n.localLabel,
            style: textTheme.titleMedium?.copyWith(
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
          color: dashboardSecondaryTextColor,
          iconSize: 24,
          tooltip: l10n.helpDialogTitle,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (hasSettingsRoute) ...[
          const SizedBox(width: 12),
          IconButton(
            key: const Key('settings-open-button'),
            onPressed: onSettingsPressed,
            icon: const Icon(Icons.settings),
            color: dashboardSecondaryTextColor,
            iconSize: 24,
            tooltip: l10n.settingsTitle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }
}

class DashboardShellHero extends StatelessWidget {
  const DashboardShellHero({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      key: const Key('dashboard-shell-hero'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.heroTitle, style: textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(l10n.heroDescription, style: textTheme.bodyMedium),
      ],
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
      padding: const EdgeInsets.all(16),
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
