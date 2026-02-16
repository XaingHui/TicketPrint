import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/storage_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final StorageService _storageService;

  SettingsViewModel(this._storageService);

  // Merchant Info
  String get merchantName => _storageService.merchantName ?? '';
  set merchantName(String value) {
    _storageService.merchantName = value;
    notifyListeners();
  }

  String get merchantPhone => _storageService.merchantPhone ?? '';
  set merchantPhone(String value) {
    _storageService.merchantPhone = value;
    notifyListeners();
  }

  String get merchantAddress => _storageService.merchantAddress ?? '';
  set merchantAddress(String value) {
    _storageService.merchantAddress = value;
    notifyListeners();
  }

  // Appearance
  String get themeMode => _storageService.themeMode;
  set themeMode(String value) {
    _storageService.themeMode = value;
    notifyListeners();
  }

  double get fontScale => _storageService.fontScale;
  set fontScale(double value) {
    _storageService.fontScale = value;
    notifyListeners();
  }

  // File Storage
  String? get savePath => _storageService.savePath;

  Future<void> pickSavePath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await setSavePath(selectedDirectory);
    }
  }
  
  Future<void> setSavePath(String? path) async {
    _storageService.savePath = path;
    notifyListeners();
  }

  // Theme Construction
  ThemeData get currentTheme {
    final fontSizeMultiplier = fontScale;
    
    // Base TextTheme scaling
    final baseTextTheme = const TextTheme(
      bodyMedium: TextStyle(fontSize: 16.0),
      bodyLarge: TextStyle(fontSize: 18.0),
      titleMedium: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
      labelLarge: TextStyle(fontSize: 16.0),
    ).apply(fontSizeFactor: fontSizeMultiplier, fontFamily: 'SimSun'); // 宋体

    if (themeMode == 'gentle') {
      return ThemeData(
        fontFamily: 'SimSun',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8FA3A8), // Muted Cyan/Grey
          surface: const Color(0xFFF5F7F8),
          secondary: const Color(0xFFA88F96),
          brightness: Brightness.light,
        ).copyWith(
          surfaceContainerLow: const Color(0xFFF0F4F5),
        ),
        textTheme: baseTextTheme,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE0E5E6),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Default Blue Theme
    return ThemeData(
      fontFamily: 'SimSun',
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
      textTheme: baseTextTheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }
}
