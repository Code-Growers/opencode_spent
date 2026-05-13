import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../dashboard/widgets/dashboard_chip_button.dart';
import '../../dashboard/widgets/dashboard_surface.dart';

class SettingsServerSection extends StatelessWidget {
  const SettingsServerSection({
    super.key,
    required this.controller,
    required this.errorText,
    required this.inputDecoration,
  });

  final TextEditingController controller;
  final String? errorText;
  final InputDecoration inputDecoration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(l10n.settingsServerUrl, style: textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: l10n.settingsServerUrl,
          textField: true,
          child: TextField(
            key: const Key('settings-server-url-field'),
            controller: controller,
            style: textTheme.bodyLarge,
            decoration: inputDecoration.copyWith(errorText: errorText),
          ),
        ),
      ],
    );
  }
}

class SettingsCredentialsSection extends StatelessWidget {
  const SettingsCredentialsSection({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.inputDecoration,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final InputDecoration inputDecoration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(l10n.settingsServerUsername, style: textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: l10n.settingsServerUsername,
          textField: true,
          child: TextField(
            key: const Key('settings-server-username-field'),
            controller: usernameController,
            style: textTheme.bodyLarge,
            decoration: inputDecoration,
          ),
        ),
        const SizedBox(height: 24),
        ExcludeSemantics(
          child: Text(l10n.settingsServerPassword, style: textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: l10n.settingsServerPassword,
          textField: true,
          child: TextField(
            key: const Key('settings-server-password-field'),
            controller: passwordController,
            style: textTheme.bodyLarge,
            obscureText: true,
            decoration: inputDecoration,
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.settingsServerAuthHint, style: textTheme.bodyMedium),
      ],
    );
  }
}

class SettingsCurrencySelector extends StatelessWidget {
  const SettingsCurrencySelector({
    super.key,
    required this.currency,
    required this.onChanged,
  });

  final SupportedCurrency currency;
  final ValueChanged<SupportedCurrency> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return MergeSemantics(
      key: const Key('settings-currency-semantics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsCurrency, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          DashboardSurface(
            backgroundColor: dashboardBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SupportedCurrency>(
                key: const Key('settings-currency-dropdown'),
                value: currency,
                isExpanded: true,
                dropdownColor: dashboardBackgroundColor,
                style: textTheme.bodyLarge,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
                items: SupportedCurrency.values.map((c) {
                  return DropdownMenuItem<SupportedCurrency>(
                    value: c,
                    child: Text(c.code),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsLanguageSelector<T> extends StatelessWidget {
  const SettingsLanguageSelector({
    super.key,
    required this.language,
    required this.systemOption,
    required this.englishOption,
    required this.czechOption,
    required this.onChanged,
  });

  final T language;
  final T systemOption;
  final T englishOption;
  final T czechOption;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return MergeSemantics(
      key: const Key('settings-language-semantics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsLanguage, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          DashboardSurface(
            backgroundColor: dashboardBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                key: const Key('settings-language-dropdown'),
                value: language,
                isExpanded: true,
                dropdownColor: dashboardBackgroundColor,
                style: textTheme.bodyLarge,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
                items: <DropdownMenuItem<T>>[
                  DropdownMenuItem<T>(
                    value: systemOption,
                    child: Text(l10n.settingsLanguageSystem),
                  ),
                  DropdownMenuItem<T>(
                    value: englishOption,
                    child: Text(l10n.settingsLanguageEnglish),
                  ),
                  DropdownMenuItem<T>(
                    value: czechOption,
                    child: Text(l10n.settingsLanguageCzech),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsActionBar extends StatelessWidget {
  const SettingsActionBar({
    super.key,
    required this.onClose,
    required this.onSave,
  });

  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: 16,
      overflowAlignment: OverflowBarAlignment.end,
      children: [
        DashboardChipButton(
          key: const Key('settings-close-button'),
          label: l10n.settingsClose,
          onTap: onClose,
        ),
        DashboardChipButton(
          key: const Key('settings-save-button'),
          label: l10n.settingsSave,
          onTap: onSave,
          isEmphasized: true,
          activeColor: dashboardStatusColor,
        ),
      ],
    );
  }
}
