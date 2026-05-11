import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dashboard_colors.dart';

const defaultOpenCodeServerUrl = 'http://localhost:4096';

OpenCodeSettings defaultOpenCodeSettings() {
  return OpenCodeSettings(
    selectedCurrency: SupportedCurrency.usd,
    openCodeServerUrl: Uri.parse(defaultOpenCodeServerUrl),
    languageCode: null,
  );
}

enum _SettingsLanguageOption { system, english, czech }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsRepository,
    this.currentSettings,
    this.onSettingsSaved,
    this.onCloseRequested,
  });

  final SettingsRepository settingsRepository;
  final OpenCodeSettings? currentSettings;
  final ValueChanged<OpenCodeSettings>? onSettingsSaved;
  final VoidCallback? onCloseRequested;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _serverUrlController;
  late final TextEditingController _serverUsernameController;
  late final TextEditingController _serverPasswordController;
  SupportedCurrency _currency = SupportedCurrency.usd;
  _SettingsLanguageOption _language = _SettingsLanguageOption.system;
  String? _serverUrlError;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(
      text:
          widget.currentSettings?.openCodeServerUrl.toString() ??
          defaultOpenCodeServerUrl,
    );
    _serverUsernameController = TextEditingController(
      text: widget.currentSettings?.openCodeServerUsername ?? '',
    );
    _serverPasswordController = TextEditingController(
      text: widget.currentSettings?.openCodeServerPassword ?? '',
    );
    if (widget.currentSettings?.selectedCurrency != null) {
      _currency = widget.currentSettings!.selectedCurrency;
    }
    _language = _languageOptionForCode(widget.currentSettings?.languageCode);
  }

  _SettingsLanguageOption _languageOptionForCode(String? languageCode) {
    return switch (languageCode) {
      'en' => _SettingsLanguageOption.english,
      'cs' => _SettingsLanguageOption.czech,
      _ => _SettingsLanguageOption.system,
    };
  }

  String? _languageCodeForOption(_SettingsLanguageOption option) {
    return switch (option) {
      _SettingsLanguageOption.system => null,
      _SettingsLanguageOption.english => 'en',
      _SettingsLanguageOption.czech => 'cs',
    };
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _serverUsernameController.dispose();
    _serverPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final normalizedServerUrl = _serverUrlController.text.trim();
    final parsedServerUrl = Uri.tryParse(normalizedServerUrl);

    final isValidServerUrl =
        parsedServerUrl != null &&
        parsedServerUrl.hasScheme &&
        (parsedServerUrl.scheme == 'http' ||
            parsedServerUrl.scheme == 'https') &&
        parsedServerUrl.host.isNotEmpty;

    if (!isValidServerUrl) {
      setState(() {
        _serverUrlError = AppLocalizations.of(
          context,
        )!.settingsServerUrlInvalid;
      });
      return;
    }

    final normalizedUsername = _serverUsernameController.text.trim();
    final normalizedPassword = _serverPasswordController.text.trim();

    final settings = OpenCodeSettings(
      openCodeServerUrl: parsedServerUrl,
      selectedCurrency: _currency,
      languageCode: _languageCodeForOption(_language),
      openCodeServerUsername: normalizedUsername.isEmpty
          ? null
          : normalizedUsername,
      openCodeServerPassword: normalizedPassword.isEmpty
          ? null
          : normalizedPassword,
    );
    await widget.settingsRepository.writeSettings(settings);
    if (mounted) {
      widget.onSettingsSaved?.call(settings);
      final onCloseRequested = widget.onCloseRequested;
      if (onCloseRequested != null) {
        onCloseRequested();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  InputDecoration _inputDecoration({String? errorText}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: dashboardBackgroundColor,
      errorText: errorText,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: dashboardBorderColor),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: dashboardStatusColor),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: dashboardBorderColor),
        borderRadius: BorderRadius.zero,
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: dashboardStatusColor),
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      key: const Key('settings-dialog'),
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dashboardSurfaceColor,
        border: Border.all(color: dashboardBorderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsTitle, style: textTheme.titleMedium),
          const SizedBox(height: 24),
          Text(l10n.settingsServerUrl, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('settings-server-url-field'),
            controller: _serverUrlController,
            style: textTheme.bodyLarge,
            decoration: _inputDecoration(errorText: _serverUrlError),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsServerUsername, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('settings-server-username-field'),
            controller: _serverUsernameController,
            style: textTheme.bodyLarge,
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsServerPassword, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            key: const Key('settings-server-password-field'),
            controller: _serverPasswordController,
            style: textTheme.bodyLarge,
            obscureText: true,
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 8),
          Text(l10n.settingsServerAuthHint, style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          Text(l10n.settingsCurrency, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: dashboardBackgroundColor,
              border: Border.all(color: dashboardBorderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SupportedCurrency>(
                value: _currency,
                isExpanded: true,
                dropdownColor: dashboardBackgroundColor,
                style: textTheme.bodyLarge,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currency = value;
                    });
                  }
                },
                items: SupportedCurrency.values.map((currency) {
                  return DropdownMenuItem<SupportedCurrency>(
                    value: currency,
                    child: Text(currency.code),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsLanguage, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: dashboardBackgroundColor,
              border: Border.all(color: dashboardBorderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_SettingsLanguageOption>(
                key: const Key('settings-language-dropdown'),
                value: _language,
                isExpanded: true,
                dropdownColor: dashboardBackgroundColor,
                style: textTheme.bodyLarge,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _language = value;
                    });
                  }
                },
                items: <DropdownMenuItem<_SettingsLanguageOption>>[
                  DropdownMenuItem<_SettingsLanguageOption>(
                    value: _SettingsLanguageOption.system,
                    child: Text(l10n.settingsLanguageSystem),
                  ),
                  DropdownMenuItem<_SettingsLanguageOption>(
                    value: _SettingsLanguageOption.english,
                    child: Text(l10n.settingsLanguageEnglish),
                  ),
                  DropdownMenuItem<_SettingsLanguageOption>(
                    value: _SettingsLanguageOption.czech,
                    child: Text(l10n.settingsLanguageCzech),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 16,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  key: const Key('settings-close-button'),
                  onTap: () {
                    final onCloseRequested = widget.onCloseRequested;
                    if (onCloseRequested != null) {
                      onCloseRequested();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    l10n.settingsClose,
                    style: textTheme.titleMedium?.copyWith(
                      color: dashboardSecondaryTextColor,
                    ),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  key: const Key('settings-save-button'),
                  onTap: _saveSettings,
                  child: Text(
                    l10n.settingsSave,
                    style: textTheme.titleMedium?.copyWith(
                      color: dashboardStatusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
