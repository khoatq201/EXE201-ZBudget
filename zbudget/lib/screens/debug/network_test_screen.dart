import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  List<String> logs = [];
  bool isLoading = false;

  void addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      logs.add('[$timestamp] $message');
    });
    print(message);
  }

  Future<void> testNetworkConnectivity() async {
    setState(() {
      isLoading = true;
      logs.clear();
    });

    addLog('🔧 Starting network connectivity test...');

    try {
      // Test 1: Check if backend is reachable
      addLog('🔧 Testing backend connectivity...');

      final baseUrl = 'http://10.0.2.2:3000/api/auth'; // Local
      addLog('🔧 Base URL: $baseUrl');

      // Test simple endpoint first
      final testResponse = await http
          .get(
            Uri.parse('$baseUrl/../health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      addLog('📥 Health check response: ${testResponse.statusCode}');

      if (testResponse.statusCode == 200) {
        addLog('✅ Backend is reachable!');
      } else {
        addLog('⚠️ Backend returned: ${testResponse.statusCode}');
      }
    } catch (e) {
      addLog('❌ Network error: $e');
    }

    try {
      // Test 2: Check Google Sign-In endpoint specifically
      addLog('🔧 Testing Google Sign-In endpoint...');

      final testBody = {
        'idToken': 'test_token',
        'email': 'test@example.com',
        'displayName': 'Test User',
      };

      final googleResponse = await http
          .post(
            Uri.parse('http://10.0.2.2:3000/api/auth/google-signin'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(testBody),
          )
          .timeout(const Duration(seconds: 10));

      addLog('📥 Google endpoint response: ${googleResponse.statusCode}');
      addLog('📥 Response body: ${googleResponse.body}');

      if (googleResponse.statusCode == 400) {
        addLog('✅ Google endpoint is reachable (400 expected for test data)');
      } else {
        addLog('⚠️ Unexpected response from Google endpoint');
      }
    } catch (e) {
      addLog('❌ Google endpoint error: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : testNetworkConnectivity,
                child: isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Testing...'),
                        ],
                      )
                    : const Text('Test Network Connectivity'),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Press the button to test network connectivity',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        Color textColor = Colors.black;
                        if (log.contains('❌')) {
                          textColor = Colors.red;
                        } else if (log.contains('✅')) {
                          textColor = Colors.green;
                        } else if (log.contains('🔧')) {
                          textColor = Colors.blue;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
