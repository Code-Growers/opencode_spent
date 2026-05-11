import '../models/open_code_settings.dart';

abstract interface class SettingsRepository {
  Future<OpenCodeSettings?> readSettings();

  Future<void> writeSettings(OpenCodeSettings settings);
}
