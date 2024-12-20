import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;
  static ThemeData? selectedTheme; // Default theme

  static Future<void> cacheInitialization() async {
    sharedPreferences = await SharedPreferences.getInstance();
    // Initialize the theme based on saved preference
    bool isDark = sharedPreferences.getBool('isDark') ?? false;
    selectedTheme = isDark ? ThemeData.dark() : ThemeData.light();
  }

  static Future<bool> setData({
    required String key,
    required dynamic value,
  }) async {
    if (value is int) {
      return await sharedPreferences.setInt(key, value);
    }
    if (value is String) {
      return await sharedPreferences.setString(key, value);
    }
    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    }
    if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    }
    return false;
  }

  static dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  static Future<bool> changeTheme() async {
    bool isDark = sharedPreferences.getBool('isDark') ?? false;
    if (isDark) {
      selectedTheme = ThemeData.light();
      return await sharedPreferences.setBool('isDark', false);
    } else {
      selectedTheme = ThemeData.dark();
      return await sharedPreferences.setBool('isDark', true);
    }
  }
}
