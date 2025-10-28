import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInTestScreen extends StatefulWidget {
  const GoogleSignInTestScreen({super.key});

  @override
  State<GoogleSignInTestScreen> createState() => _GoogleSignInTestScreenState();
}

class _GoogleSignInTestScreenState extends State<GoogleSignInTestScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Remove clientId for Android - it should use google-services.json
  );

  final List<String> _logs = [];
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print('🔥 DEBUG: $message');
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _log('🚀 Bắt đầu Google Sign-In test');

      // Kiểm tra signed in status
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      _log('Current user: ${currentUser?.email ?? "null"}');

      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      _log('✅ Signed out');

      // Attempt sign in
      _log('📱 Attempting Google Sign-In...');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        _log('❌ User cancelled sign in');
        return;
      }

      _log('✅ Account selected: ${account.email}');
      _log('👤 Display name: ${account.displayName}');
      _log('🖼️ Photo URL: ${account.photoUrl}');

      // Get authentication details
      _log('🔑 Getting authentication details...');
      final GoogleSignInAuthentication auth = await account.authentication;

      _log(
        '🎫 Access Token: ${auth.accessToken != null && auth.accessToken!.length > 20 ? auth.accessToken!.substring(0, 20) : auth.accessToken}...',
      );
      _log(
        '🎫 ID Token: ${auth.idToken != null && auth.idToken!.length > 20 ? auth.idToken!.substring(0, 20) : auth.idToken}...',
      );

      // Test backend API call
      _log('🌐 Testing backend API call...');
      await _testBackendCall(account, auth);
    } catch (e, stackTrace) {
      _log('❌ Error during Google Sign-In: $e');
      _log(
        '📋 Stack trace: ${stackTrace.toString().length > 200 ? stackTrace.toString().substring(0, 200) : stackTrace.toString()}...',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackendCall(
    GoogleSignInAccount account,
    GoogleSignInAuthentication auth,
  ) async {
    try {
      const String baseUrl =
          'https://exe201-zbudget.onrender.com'; // Android emulator

      final Map<String, dynamic> requestBody = {
        'email': account.email,
        'displayName': account.displayName,
        'photoUrl': account.photoUrl,
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
      };

      _log('📤 Sending request to backend...');
      final requestBodyStr = jsonEncode(requestBody);
      _log(
        '📋 Request body: ${requestBodyStr.length > 100 ? requestBodyStr.substring(0, 100) : requestBodyStr}...',
      );

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/google-signin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      _log('📥 Response status: ${response.statusCode}');
      _log('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log('✅ Backend response success: ${data['success']}');
        _log('💬 Message: ${data['message']}');
        if (data['user'] != null) {
          _log('👤 User ID: ${data['user']['id']}');
          _log('📧 User email: ${data['user']['email']}');
        }
      } else {
        _log('❌ Backend error: ${response.statusCode}');
        _log('💬 Error message: ${response.body}');
      }
    } catch (e) {
      _log('❌ Network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testGoogleSignIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _isLoading ? 'Testing...' : 'Test Google Sign-In',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Logs:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: log));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Log copied to clipboard'),
                          ),
                        );
                      },
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: log.contains('❌')
                              ? Colors.red
                              : log.contains('✅')
                              ? Colors.green
                              : log.contains('🔑') || log.contains('🎫')
                              ? Colors.orange
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
