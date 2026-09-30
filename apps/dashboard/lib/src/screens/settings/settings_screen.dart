import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dashboard_colors.dart';
import '../dashboard/widgets/dashboard_surface.dart';
import 'widgets/settings_form_sections.dart';
import 'widgets/usage_sources_section.dart';
import 'widgets/api_pricing_section.dart';

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
    this.localUsageSources,
    this.pricingRepository,
    this.sessionRepository,
    this.pickSourceDirectory,
    this.onUsageChanged,
    this.onSettingsSaved,
    this.onCloseRequested,
    this.bounded = false,
  });

  final bool bounded;
  final LocalUsageSources? localUsageSources;
  final PricingRepository? pricingRepository;
  final OpenCodeSessionRepository? sessionRepository;
  final Future<String?> Function()? pickSourceDirectory;
  final VoidCallback? onUsageChanged;
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

  InputDecoration _inputDecoration(BuildContext context, {String? errorText}) {
    return const InputDecoration()
        .applyDefaults(Theme.of(context).inputDecorationTheme)
        .copyWith(
          errorText: errorText,
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: dashboardErrorColor),
            borderRadius: BorderRadius.zero,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: dashboardErrorColor),
            borderRadius: BorderRadius.zero,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsServerSection(
          controller: _serverUrlController,
          errorText: _serverUrlError,
          inputDecoration: _inputDecoration(context),
        ),
        const SizedBox(height: 24),
        SettingsCredentialsSection(
          usernameController: _serverUsernameController,
          passwordController: _serverPasswordController,
          inputDecoration: _inputDecoration(context),
        ),
        const SizedBox(height: 24),
        SettingsCurrencySelector(
          currency: _currency,
          onChanged: (value) {
            setState(() {
              _currency = value;
            });
          },
        ),
        const SizedBox(height: 24),
        SettingsLanguageSelector<_SettingsLanguageOption>(
          language: _language,
          systemOption: _SettingsLanguageOption.system,
          englishOption: _SettingsLanguageOption.english,
          czechOption: _SettingsLanguageOption.czech,
          onChanged: (value) {
            setState(() {
              _language = value;
            });
          },
        ),
        const SizedBox(height: 24),
        UsageSourcesSection(
          sources: widget.localUsageSources,
          pickDirectory: widget.pickSourceDirectory,
          onChanged: widget.onUsageChanged ?? () {},
        ),
        if (widget.pricingRepository != null &&
            widget.sessionRepository != null) ...[
          const SizedBox(height: 24),
          ApiPricingSection(
            repository: widget.pricingRepository!,
            sessions: widget.sessionRepository!,
            onChanged: widget.onUsageChanged ?? () {},
          ),
        ],
      ],
    );
    final actions = SettingsActionBar(
      onClose: () {
        final onCloseRequested = widget.onCloseRequested;
        if (onCloseRequested != null) {
          onCloseRequested();
        } else {
          Navigator.of(context).pop();
        }
      },
      onSave: _saveSettings,
    );
    final panel = DashboardSurface(
      key: const Key('settings-dialog'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.settingsTitle, style: textTheme.titleLarge),
          ),
          const SizedBox(height: 24),
          if (widget.bounded)
            Expanded(
              child: SingleChildScrollView(
                key: const Key('settings-form-scroll'),
                child: form,
              ),
            )
          else
            form,
          const SizedBox(height: 16),
          const Divider(color: dashboardBorderColor),
          const SizedBox(height: 8),
          actions,
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: widget.bounded
          ? LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: constraints.maxHeight.clamp(0, 860).toDouble(),
                child: panel,
              ),
            )
          : panel,
    );
  }
}
