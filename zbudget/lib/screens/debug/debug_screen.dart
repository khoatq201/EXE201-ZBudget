import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/debug_service.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              context.read<DebugService>().clear();
            },
          ),
        ],
      ),
      body: Consumer<DebugService>(
        builder: (context, debugService, child) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Total logs: ${debugService.logs.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: debugService.logs.isEmpty
                      ? const Center(
                          child: Text(
                            'No logs yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          reverse: true, // Show newest logs at top
                          itemCount: debugService.logs.length,
                          itemBuilder: (context, index) {
                            final log = debugService
                                .logs[debugService.logs.length - 1 - index];

                            Color textColor = Colors.black;
                            if (log.contains('❌') || log.contains('Error')) {
                              textColor = Colors.red;
                            } else if (log.contains('✅') ||
                                log.contains('success')) {
                              textColor = Colors.green;
                            } else if (log.contains('🔧') ||
                                log.contains('🚀')) {
                              textColor = Colors.blue;
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
