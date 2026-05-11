import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

final class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore(this._preferences);

  factory SharedPreferencesKeyValueStore.create({
    SharedPreferencesAsync? preferences,
  }) {
    return SharedPreferencesKeyValueStore(
      preferences ?? SharedPreferencesAsync(),
    );
  }

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readString(String key) {
    return _preferences.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
