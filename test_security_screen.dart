// Test file for Security Screen functionality
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'zbudget/lib/services/security_service.dart';
import 'zbudget/lib/models/settings/security_settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Screen Test',
      home: ChangeNotifierProvider(
        create: (context) => SecurityService(),
        child: SecurityScreenTest(),
      ),
    );
  }
}

class SecurityScreenTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Screen Test'),
      ),
      body: Consumer<SecurityService>(
        builder: (context, securityService, child) {
          if (securityService.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final settings = securityService.securitySettings;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Level Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Level: ${settings.securityLevel}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('Is Secure: ${settings.isSecure}'),
                        Text('Biometric Enabled: ${settings.isBiometricEnabled}'),
                        Text('Two Factor Enabled: ${settings.isTwoFactorEnabled}'),
                        Text('Auto Lock Enabled: ${settings.isAutoLockEnabled}'),
                        Text('Data Encryption: ${settings.isDataEncryptionEnabled}'),
                        Text('Active Sessions: ${settings.activeSessions.length}'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Test Buttons
                ElevatedButton(
                  onPressed: () async {
                    final success = await securityService.enableBiometric();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Biometric enable result: $success')),
                    );
                  },
                  child: Text('Test Enable Biometric'),
                ),
                
                ElevatedButton(
                  onPressed: () async {
                    final success = await securityService.disableBiometric();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Biometric disable result: $success')),
                    );
                  },
                  child: Text('Test Disable Biometric'),
                ),
                
                ElevatedButton(
                  onPressed: () async {
                    await securityService.toggleAutoLock(!settings.isAutoLockEnabled);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Auto lock toggled')),
                    );
                  },
                  child: Text('Test Toggle Auto Lock'),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    final recommendations = securityService.getSecurityRecommendations();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Security Recommendations'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: recommendations.map((rec) => Text('• $rec')).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('Show Security Recommendations'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
