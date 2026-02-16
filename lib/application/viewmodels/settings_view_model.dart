import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/storage_service.dart';

enum AppTheme {
  pureWhite,
  candyPink,
  skyBlue,
  dark,
}

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
  AppTheme get currentThemeType {
    final mode = _storageService.themeMode;
    return AppTheme.values.firstWhere(
      (e) => e.toString().split('.').last == mode,
      orElse: () => AppTheme.pureWhite,
    );
  }

  Future<void> setTheme(AppTheme theme) async {
    _storageService.themeMode = theme.toString().split('.').last;
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

  Future<void> clearSavePath() async {
    await setSavePath(null);
  }

  // Background Gradient Getter
  LinearGradient? get currentBackgroundGradient {
    switch (currentThemeType) {
      case AppTheme.pureWhite:
        return null; // No gradient
      case AppTheme.candyPink:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFEE1E8), // Soft Pink
            Color(0xFFE3E4FF), // Lawender
            Color(0xFFDFF2FF), // Baby Blue
          ],
        );
      case AppTheme.skyBlue:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF81D4FA), // More vibrant Light Blue
            Color(0xFFE1F5FE), // Very light blue
            Color(0xFFFFFFFF), // White
          ],
        );
      case AppTheme.dark:
        return null; // Dark mode usually solid
    }
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

    switch (currentThemeType) {
      case AppTheme.candyPink:
        return _buildTheme(
          seed: const Color(0xFFE040FB), // Purple Accent
          brightness: Brightness.light,
          baseText: baseTextTheme,
          scaffoldTransparent: true,
        );
      case AppTheme.skyBlue:
        return _buildTheme(
          seed: const Color(0xFF29B6F6), // Stronger Blue
          brightness: Brightness.light,
          baseText: baseTextTheme,
          scaffoldTransparent: true,
        );
      case AppTheme.dark:
        return _buildTheme(
          seed: const Color(0xFFD0BCFF), // Muted Lavender/Purple for Dark Mode
          brightness: Brightness.dark,
          baseText: baseTextTheme,
          scaffoldTransparent: false,
        );
      case AppTheme.pureWhite:
      default:
        return ThemeData(
          fontFamily: 'SimSun',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE0E0E0), // Neutral Grey seed
            surface: Colors.white, // Force surface to white
            surfaceContainer: Colors.white,
            surfaceContainerLow: Colors.white,
            surfaceContainerLowest: Colors.white,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: baseTextTheme,
          scaffoldBackgroundColor: Colors.white, // Force opaque white
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent, // No tint
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: const Color(0xFFF5F5F5), // Light grey for cards to standout slightly on white
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        );
    }
  }

  ThemeData _buildTheme({
    required Color seed,
    required Brightness brightness,
    required TextTheme baseText,
    required bool scaffoldTransparent,
  }) {
    return ThemeData(
      fontFamily: 'SimSun',
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      useMaterial3: true,
      textTheme: baseText,
      scaffoldBackgroundColor: scaffoldTransparent ? Colors.transparent : null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        // Make inputs slightly transparent on gradients? Maybe just white/surface
        fillColor: null, 
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light ? Colors.white.withOpacity(0.8) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
