import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../utils/device_info_helper.dart';

class DeviceInfoTestScreen extends StatefulWidget {
  const DeviceInfoTestScreen({Key? key}) : super(key: key);

  @override
  State<DeviceInfoTestScreen> createState() => _DeviceInfoTestScreenState();
}

class _DeviceInfoTestScreenState extends State<DeviceInfoTestScreen> {
  String _deviceInfo = 'Loading...';
  String _userAgent = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = await DeviceInfoHelper.getDeviceInfoJson();
      final userAgent = await DeviceInfoHelper.buildCustomUserAgent();

      setState(() {
        _deviceInfo = deviceInfo;
        _userAgent = userAgent;
      });

      debugPrint('🔍 Device Info: $deviceInfo');
      debugPrint('🔍 User Agent: $userAgent');
    } catch (e) {
      setState(() {
        _deviceInfo = 'Error: $e';
        _userAgent = 'Error: $e';
      });
      debugPrint('❌ Error getting device info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Info Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Info JSON:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _deviceInfo,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'User Agent:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _userAgent,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _loadDeviceInfo,
                child: const Text('Reload Device Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
