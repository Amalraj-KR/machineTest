import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.machine_test/platform',
  );
  static const EventChannel _batteryChannel = EventChannel(
    'com.example.machine_test/battery',
  );

  static Future<String> getDeviceModel() async {
    try {
      final String model = await _channel.invokeMethod('getDeviceModel');
      return model;
    } catch (e) {
      return 'Unknown Device';
    }
  }

  static Future<String> getAndroidVersion() async {
    try {
      final String version = await _channel.invokeMethod('getAndroidVersion');
      return version;
    } catch (e) {
      return 'Unknown Version';
    }
  }

  static Future<Uint8List?> pickImage() async {
    try {
      final Uint8List? image = await _channel.invokeMethod('pickImage');
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  static Stream<int> getBatteryLevel() {
    return _batteryChannel.receiveBroadcastStream().map(
      (dynamic level) => level as int,
    );
  }

  static Future<int> getCurrentBatteryLevel() async {
    try {
      final int level = await _channel.invokeMethod('getBatteryLevel');
      return level;
    } catch (e) {
      return 0;
    }
  }
}
