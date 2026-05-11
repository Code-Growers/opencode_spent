import 'dart:convert';

import 'supported_currency.dart';

const _languageCodeUnchanged = Object();
const _openCodeServerUsernameUnchanged = Object();
const _openCodeServerPasswordUnchanged = Object();

final class OpenCodeSettings {
  const OpenCodeSettings({
    required this.selectedCurrency,
    required this.openCodeServerUrl,
    this.languageCode,
    this.openCodeServerUsername,
    this.openCodeServerPassword,
  });

  final SupportedCurrency selectedCurrency;
  final Uri openCodeServerUrl;
  final String? languageCode;
  final String? openCodeServerUsername;
  final String? openCodeServerPassword;

  bool get hasServerBasicAuth {
    final password = openCodeServerPassword?.trim();
    return password != null && password.isNotEmpty;
  }

  String? get effectiveOpenCodeServerUsername {
    if (!hasServerBasicAuth) {
      return null;
    }

    final username = openCodeServerUsername?.trim();
    if (username == null || username.isEmpty) {
      return 'opencode';
    }

    return username;
  }

  String? get openCodeServerAuthorizationHeader {
    final password = openCodeServerPassword?.trim();
    final username = effectiveOpenCodeServerUsername;
    if (!_allowsBasicAuthTransport ||
        username == null ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    final credentials = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $credentials';
  }

  bool get _allowsBasicAuthTransport {
    final scheme = openCodeServerUrl.scheme.toLowerCase();
    if (scheme == 'https') {
      return true;
    }

    if (scheme != 'http') {
      return false;
    }

    final host = openCodeServerUrl.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  OpenCodeSettings copyWith({
    SupportedCurrency? selectedCurrency,
    Uri? openCodeServerUrl,
    Object? languageCode = _languageCodeUnchanged,
    Object? openCodeServerUsername = _openCodeServerUsernameUnchanged,
    Object? openCodeServerPassword = _openCodeServerPasswordUnchanged,
  }) {
    return OpenCodeSettings(
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      openCodeServerUrl: openCodeServerUrl ?? this.openCodeServerUrl,
      languageCode: identical(languageCode, _languageCodeUnchanged)
          ? this.languageCode
          : languageCode as String?,
      openCodeServerUsername:
          identical(openCodeServerUsername, _openCodeServerUsernameUnchanged)
          ? this.openCodeServerUsername
          : openCodeServerUsername as String?,
      openCodeServerPassword:
          identical(openCodeServerPassword, _openCodeServerPasswordUnchanged)
          ? this.openCodeServerPassword
          : openCodeServerPassword as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenCodeSettings &&
            other.selectedCurrency == selectedCurrency &&
            other.openCodeServerUrl == openCodeServerUrl &&
            other.languageCode == languageCode &&
            other.openCodeServerUsername == openCodeServerUsername &&
            other.openCodeServerPassword == openCodeServerPassword;
  }

  @override
  int get hashCode => Object.hash(
    selectedCurrency,
    openCodeServerUrl,
    languageCode,
    openCodeServerUsername,
    openCodeServerPassword,
  );
}
