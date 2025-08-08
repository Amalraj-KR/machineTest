import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/platform_provider.dart';

class BatteryOverlay extends StatelessWidget {
  final Widget child;

  const BatteryOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            bottom: 24,
            right: 24,
            child: Consumer<PlatformProvider>(
              builder: (context, platformProvider, _) {
                final batteryLevel = platformProvider.batteryLevel;
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getBatteryColor(batteryLevel),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getBatteryColor(
                          batteryLevel,
                        ).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getBatteryIcon(batteryLevel),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$batteryLevel%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int level) {
    if (level <= 15) {
      return const Color(0xFFEF4444);
    } else if (level <= 30) {
      return const Color(0xFFF97316);
    } else if (level <= 50) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF10B981);
    }
  }

  IconData _getBatteryIcon(int level) {
    if (level <= 15) {
      return Icons.battery_alert_rounded;
    } else if (level <= 30) {
      return Icons.battery_2_bar_rounded;
    } else if (level <= 50) {
      return Icons.battery_4_bar_rounded;
    } else if (level <= 75) {
      return Icons.battery_5_bar_rounded;
    } else {
      return Icons.battery_full_rounded;
    }
  }
}
