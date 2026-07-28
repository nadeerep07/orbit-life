import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeViewModel extends ChangeNotifier {
  static const String _boxName = 'settingsBox';
  static const String _themeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  ThemeViewModel() {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        var box = Hive.box(_boxName);
        var savedTheme = box.get(_themeKey);
        if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      if (Hive.isBoxOpen(_boxName)) {
        var box = Hive.box(_boxName);
        String themeString;
        if (mode == ThemeMode.light) {
          themeString = 'light';
        } else if (mode == ThemeMode.dark) {
          themeString = 'dark';
        } else {
          themeString = 'system';
        }
        await box.put(_themeKey, themeString);
      }
    } catch (_) {}
  }
}
