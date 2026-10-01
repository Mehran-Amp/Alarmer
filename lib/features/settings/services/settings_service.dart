import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

/// Local-First Persistent Settings Service.
/// Stores user preferences in `<storageDirectoryPath>/settings.json`.
class SettingsService extends ChangeNotifier {
  final String _storageDirectoryPath;
  AppSettings _settings = const AppSettings();

  SettingsService(this._storageDirectoryPath);

  AppSettings get settings => _settings;

  File get _file => File('$_storageDirectoryPath/settings.json');

  Future<void> load() async {
    try {
      final file = _file;
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          _settings = AppSettings.fromJson(decoded);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to load settings.json: $e');
    }
    _settings = const AppSettings();
    notifyListeners();
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    try {
      final file = _file;
      await file.writeAsString(jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Failed to save settings.json: $e');
    }
  }

  Future<void> setPalette(AppThemePalette palette) async {
    await update(_settings.copyWith(themePalette: palette));
  }

  Future<void> setLanguage(String langCode) async {
    await update(_settings.copyWith(language: langCode));
  }

  Future<void> toggleSound(bool val) async {
    await update(_settings.copyWith(soundEnabled: val));
  }

  Future<void> toggleVibration(bool val) async {
    await update(_settings.copyWith(vibrationEnabled: val));
  }

  Future<void> setSoundName(String soundId) async {
    await update(_settings.copyWith(soundName: soundId));
  }

  Future<void> setAlarmVolume(double volume) async {
    await update(_settings.copyWith(alarmVolume: volume));
  }
}
