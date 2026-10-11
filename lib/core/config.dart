/// Build-time settings. Override with: flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
class AppConfig {
  AppConfig._();

  /// Default works for the Android emulator talking to a backend on the same PC
  /// (10.0.2.2 is the emulator's alias for the host machine).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Shown in the app bar and on the login screen. Replace per customer:
  /// flutter run --dart-define=SHOP_NAME="ชื่อร้านของลูกค้า"
  static const shopName = String.fromEnvironment(
    'SHOP_NAME',
    defaultValue: 'ร้านกาแฟตัวอย่าง',
  );
}
