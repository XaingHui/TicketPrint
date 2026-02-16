import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 存储商户名称
  String? get merchantName => _prefs.getString('merchant_name');
  set merchantName(String? value) {
    if (value == null) {
      _prefs.remove('merchant_name');
    } else {
      _prefs.setString('merchant_name', value);
    }
  }

  // 存储商户电话
  String? get merchantPhone => _prefs.getString('merchant_phone');
  set merchantPhone(String? value) {
    if (value == null) {
      _prefs.remove('merchant_phone');
    } else {
      _prefs.setString('merchant_phone', value);
    }
  }

  // 存储商户地址
  String? get merchantAddress => _prefs.getString('merchant_address');
  set merchantAddress(String? value) {
    if (value == null) {
      _prefs.remove('merchant_address');
    } else {
      _prefs.setString('merchant_address', value);
    }
  }

  // 主题模式 ('default', 'gentle')
  String get themeMode => _prefs.getString('theme_mode') ?? 'default';
  set themeMode(String value) {
    _prefs.setString('theme_mode', value);
  }

  // 字体缩放比例 (0.8 - 1.5)
  double get fontScale => _prefs.getDouble('font_scale') ?? 1.0;
  set fontScale(double value) {
    _prefs.setDouble('font_scale', value);
  }
  // 存储文件保存位置
  String? get savePath => _prefs.getString('save_path');
  set savePath(String? value) {
    if (value == null) {
      _prefs.remove('save_path');
    } else {
      _prefs.setString('save_path', value);
    }
  }
}
