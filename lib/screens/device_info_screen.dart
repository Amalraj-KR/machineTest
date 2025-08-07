import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/platform_provider.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformProvider>().fetchDeviceInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlatformProvider>(
      builder: (context, platformProvider, child) {
        if (platformProvider.isLoading) {
          return _buildLoadingState();
        }

        if (platformProvider.error != null) {
          return _buildErrorState(context, platformProvider);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Device Status Header
              _buildDeviceStatusHeader(context, platformProvider),
              const SizedBox(height: 24),

              // Device Information Card
              _buildDeviceInfoCard(context, platformProvider),
              const SizedBox(height: 20),

              // Application Information Card
              _buildAppInfoCard(context, platformProvider),
              const SizedBox(height: 20),

              // System Metrics Card
              _buildSystemMetricsCard(context, platformProvider),
              const SizedBox(height: 20),

              // Refresh Button
              _buildRefreshButton(context, platformProvider),

              const SizedBox(height: 100), // Space for battery overlay
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Fetching Device Information...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic platformProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFFF6B6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              platformProvider.error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              platformProvider.clearError();
              platformProvider.fetchDeviceInfo();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusHeader(
    BuildContext context,
    dynamic platformProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Bright blue
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.phone_android_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${platformProvider.deviceModel} • Android ${platformProvider.androidVersion}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildBatteryIndicator(platformProvider.batteryLevel),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator(int batteryLevel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getBatteryIcon(batteryLevel), size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$batteryLevel%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard(BuildContext context, dynamic platformProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smartphone_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Device Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              context,
              Icons.phone_android_rounded,
              'Device Model',
              platformProvider.deviceModel,
              const Color(0xFF3B82F6),
            ),
            _buildModernInfoRow(
              context,
              Icons.android_rounded,
              'Android Version',
              platformProvider.androidVersion,
              const Color(0xFF10B981),
            ),
            _buildModernInfoRow(
              context,
              Icons.memory_rounded,
              'Platform',
              'Android',
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, dynamic platformProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Application Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              context,
              Icons.label_rounded,
              'App Name',
              platformProvider.appName,
              const Color(0xFF3B82F6),
            ),
            _buildModernInfoRow(
              context,
              Icons.code_rounded,
              'Version',
              platformProvider.appVersion,
              const Color(0xFF10B981),
            ),
            _buildModernInfoRow(
              context,
              Icons.flutter_dash_rounded,
              'Framework',
              'Flutter',
              const Color(0xFF8B5CF6),
            ),
            _buildModernInfoRow(
              context,
              Icons.build_rounded,
              'Build Number',
              platformProvider.buildNumber,
              const Color(0xFFFF6B6B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMetricsCard(
    BuildContext context,
    dynamic platformProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'System Metrics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    Icons.battery_charging_full_rounded,
                    'Battery',
                    '${platformProvider.batteryLevel}%',
                    _getBatteryColor(platformProvider.batteryLevel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    Icons.signal_cellular_4_bar_rounded,
                    'Status',
                    'Online',
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context, dynamic platformProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          platformProvider.fetchDeviceInfo();
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh Information'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  Color _getBatteryColor(int level) {
    if (level <= 15) {
      return Colors.red;
    } else if (level <= 30) {
      return Colors.orange;
    } else if (level <= 50) {
      return Colors.yellow.shade700;
    } else {
      return Colors.green;
    }
  }
}
