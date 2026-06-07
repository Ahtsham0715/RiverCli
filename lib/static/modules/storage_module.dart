import '../../models/module.dart';

/// Local persistence: a typed SharedPreferences wrapper (with Riverpod
/// providers) and an encrypted secure-storage service.
final Module storageModule = Module(
  key: 'storage',
  title: 'Storage (SharedPreferences + secure storage)',
  description:
      'LocalDB typed SharedPreferences wrapper with Riverpod providers, plus SecureStorageService (flutter_secure_storage).',
  packages: [
    'shared_preferences',
    'flutter_secure_storage',
    'flutter_riverpod'
  ],
  dependsOn: ['config'],
  folders: ['lib/data/provider/local_storage', 'lib/app/services'],
  files: {
    'lib/data/provider/local_storage/local_db.dart': r'''
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/config/global_vars.dart';

/// A typed wrapper around [SharedPreferences] with a few session helpers.
/// Call [init] once (e.g. in `main()`) before reading or writing.
class LocalDB {
  late SharedPreferences pref;

  static const String _authTokenKey = 'authToken';

  Future<void> init() async {
    pref = await SharedPreferences.getInstance();
    Globals.authToken = pref.getString(_authTokenKey) ?? '';
  }

  Future<void> setData(String key, dynamic value) async {
    if (value is Map<String, dynamic>) {
      await pref.setString(key, jsonEncode(value));
    } else if (value is int) {
      await pref.setInt(key, value);
    } else if (value is double) {
      await pref.setDouble(key, value);
    } else if (value is bool) {
      await pref.setBool(key, value);
    } else if (value is List<String>) {
      await pref.setStringList(key, value);
    } else if (value is String) {
      await pref.setString(key, value);
    }
  }

  dynamic getData(String key, {Type? type}) {
    if (type == Map) {
      final jsonString = pref.getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } else if (type == List) {
      return pref.getStringList(key);
    }
    return pref.get(key);
  }

  String? getString(String key) => pref.getString(key);

  bool getBool(String key, {bool defaultValue = false}) =>
      pref.getBool(key) ?? defaultValue;

  Future<void> saveAuthToken(String token) async {
    await pref.setString(_authTokenKey, token);
    Globals.authToken = token;
  }

  Future<String?> getAuthToken() async => pref.getString(_authTokenKey);

  Future<void> remove(String key) async {
    await pref.remove(key);
  }

  Future<void> clear() async {
    await pref.clear();
    Globals.authToken = '';
  }
}

/// Provides an (uninitialized) [LocalDB]. Call `init()` before use.
final localDBProvider = Provider<LocalDB>((ref) => LocalDB());

/// Provides a [LocalDB] that has already been initialized.
final initializedLocalDBProvider = FutureProvider<LocalDB>((ref) async {
  final db = LocalDB();
  await db.init();
  return db;
});
''',
    'lib/app/services/secure_storage_service.dart': r'''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-encrypted key/value storage for sensitive values (tokens, secrets).
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  IOSOptions _iosOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      );

  AndroidOptions _androidOptions() => const AndroidOptions();

  Future<void> write({required String key, required String value}) async {
    await _storage.write(
      key: key,
      value: value,
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }

  Future<String?> read({required String key}) async {
    return _storage.read(
      key: key,
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(
      key: key,
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }

  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(
      key: key,
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll(
      iOptions: _iosOptions(),
      aOptions: _androidOptions(),
    );
  }
}
''',
  },
);
