import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/platform_service.dart';

class PlatformProvider with ChangeNotifier {
  String _deviceModel = 'Unknown';
  String _androidVersion = 'Unknown';
  Uint8List? _selectedImage;
  int _batteryLevel = 0;
  bool _isLoading = false;
  String? _error;
  String _appName = 'Unknown';
  String _appVersion = 'Unknown';
  String _buildNumber = 'Unknown';

  String get deviceModel => _deviceModel;
  String get androidVersion => _androidVersion;
  Uint8List? get selectedImage => _selectedImage;
  int get batteryLevel => _batteryLevel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get appName => _appName;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;

  PlatformProvider() {
    _initializePlatformInfo();
    _initializeBatteryStream();
  }

  Future<void> _initializePlatformInfo() async {
    await fetchDeviceInfo();
    await _loadAppInfo();
    await _getCurrentBatteryLevel();
  }

  void _initializeBatteryStream() {
    PlatformService.getBatteryLevel().listen(
      (level) {
        _batteryLevel = level;
        notifyListeners();
      },
      onError: (error) {
        // Battery stream error, fallback to periodic updates
        _startBatteryPolling();
      },
    );
  }

  void _startBatteryPolling() {
    Stream.periodic(const Duration(seconds: 30)).listen((_) async {
      await _getCurrentBatteryLevel();
    });
  }

  Future<void> _getCurrentBatteryLevel() async {
    try {
      _batteryLevel = await PlatformService.getCurrentBatteryLevel();
      notifyListeners();
    } catch (e) {
      // Battery level not critical, fail silently
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final String pubspecContent = await rootBundle.loadString('pubspec.yaml');
      final lines = pubspecContent.split('\n');

      for (String line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('name:')) {
          _appName = trimmedLine.split(':')[1].trim();
        } else if (trimmedLine.startsWith('version:')) {
          final versionPart = trimmedLine.split(':')[1].trim();
          final parts = versionPart.split('+');
          _appVersion = parts[0];
          _buildNumber = parts.length > 1 ? parts[1] : '1';
        }
      }
      notifyListeners();
    } catch (e) {
      // Fallback to default values if pubspec.yaml cannot be read
      _appName = 'Machine Test';
      _appVersion = '1.0.0';
      _buildNumber = '1';
    }
  }

  Future<void> fetchDeviceInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _deviceModel = await PlatformService.getDeviceModel();
      _androidVersion = await PlatformService.getAndroidVersion();
      await _loadAppInfo();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final image = await PlatformService.pickImage();
      _selectedImage = image;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
