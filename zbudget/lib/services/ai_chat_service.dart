import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/ai_models.dart';
import '../utils/auth_utils.dart';

class AiChatService {
  final String baseUrl = ApiConfig.baseUrl;
  String? _currentSessionId;

  // Quick action suggestions - Tập trung vào tài chính
  static final List<QuickAction> quickActions = [
    QuickAction(
      id: 'analyze_spending',
      title: 'Phân tích chi tiêu',
      message: 'Phân tích chi tiêu tháng này',
      icon: Icons.analytics,
    ),
    QuickAction(
      id: 'saving_advice',
      title: 'Tư vấn tiết kiệm',
      message: 'Cách tiết kiệm hiệu quả?',
      icon: Icons.savings,
    ),
    QuickAction(
      id: 'budget_review',
      title: 'Đánh giá ngân sách',
      message: 'Ngân sách có hợp lý không?',
      icon: Icons.account_balance_wallet,
    ),
    QuickAction(
      id: 'expense_insights',
      title: 'Chi tiêu bất thường',
      message: 'Có chi tiêu nào bất thường?',
      icon: Icons.warning_amber,
    ),
  ];

  // Start or resume chat session (reuse existing active session if available)
  Future<String> startChatSession({bool forceNew = false}) async {
    final token = await AuthUtils.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Check if we have an active session (unless forced to create new)
    if (!forceNew) {
      final existingSessionId = await _getActiveSessionId();
      if (existingSessionId != null) {
        // Validate session exists in database
        final isValid = await _validateSession(existingSessionId, token);
        if (isValid) {
          debugPrint('♻️ Reusing existing session: $existingSessionId');
          _currentSessionId = existingSessionId;
          return existingSessionId;
        } else {
          debugPrint('⚠️ Cached session invalid, clearing and creating new...');
          await clearActiveSession();
        }
      }
    }

    // Create new session
    debugPrint('🆕 Creating new chat session...');
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _currentSessionId = data['session']['sessionId'];
      await _saveSessionLocally(_currentSessionId!);
      debugPrint('✅ New session created: $_currentSessionId');
      return _currentSessionId!;
    }
    throw Exception('Failed to start chat session');
  }

  // Validate session exists in database
  Future<bool> _validateSession(String sessionId, String token) async {
    try {
      debugPrint('🔍 Validating session: $sessionId');
      final response = await http.get(
        Uri.parse('$baseUrl/ai/chat/history/$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Session exists in database');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('❌ Session not found (404) - will create new session');
        return false;
      } else {
        debugPrint(
          '⚠️ Session validation returned ${response.statusCode} - treating as invalid',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error validating session: $e');
      return false;
    }
  }

  // Get active session ID from local storage
  Future<String?> _getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('active_chat_session');
      return sessionId;
    } catch (e) {
      debugPrint('Error getting active session: $e');
      return null;
    }
  }

  // Clear active session (call when ending chat)
  Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_chat_session');
      _currentSessionId = null;
      debugPrint('🗑️ Active session cleared');
    } catch (e) {
      debugPrint('Error clearing active session: $e');
    }
  }

  // Load existing session
  Future<String> loadExistingSession(String sessionId) async {
    _currentSessionId = sessionId;
    await _saveSessionLocally(sessionId);
    return sessionId;
  }

  // Send message with improved streaming
  Stream<String> sendMessageWithStreaming(
    String sessionId,
    String message,
  ) async* {
    final token = await AuthUtils.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final client = http.Client();
    String actualSessionId = sessionId;

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/ai/chat/message'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });

      request.body = json.encode({'sessionId': sessionId, 'message': message});

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to send message');
      }

      String fullResponse = '';

      await for (var chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              break;
            }

            try {
              final jsonData = json.decode(data);

              // Handle session creation
              if (jsonData['type'] == 'session_created') {
                actualSessionId = jsonData['sessionId'];
                _currentSessionId = actualSessionId;
                await _saveSessionLocally(actualSessionId);
                print('🆕 New session created: $actualSessionId');
                continue;
              }

              // Handle streaming content
              if (jsonData['type'] == 'chunk' && jsonData['content'] != null) {
                final content = jsonData['content'] as String;
                if (content.isNotEmpty) {
                  fullResponse += content;

                  // Yield chunk directly - backend already handles streaming
                  // Don't split to prevent Vietnamese encoding issues
                  yield content;
                  await Future.delayed(const Duration(milliseconds: 50));
                }
              }
            } catch (e) {
              // Skip invalid JSON
              print('Invalid JSON: $data');
              continue;
            }
          }
        }
      }

      // Save message locally with actual session ID
      await _saveMessageLocally(actualSessionId, message, fullResponse);
    } finally {
      client.close();
    }
  }

  // Save session locally as active session
  Future<void> _saveSessionLocally(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_chat_session', sessionId);
    debugPrint('💾 Saved active session: $sessionId');
  }

  // Save message to local storage
  Future<void> _saveMessageLocally(
    String sessionId,
    String userMessage,
    String aiResponse,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ai_chat_$sessionId';

    final existingData = prefs.getString(key);
    List<Map<String, dynamic>> messages = [];

    if (existingData != null) {
      messages = List<Map<String, dynamic>>.from(json.decode(existingData));
    }

    messages.add({
      'role': 'user',
      'content': userMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });

    messages.add({
      'role': 'assistant',
      'content': aiResponse,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(key, json.encode(messages));
  }

  // Get chat history from backend
  Future<List<ChatMessage>> getChatHistory(String sessionId) async {
    final token = await AuthUtils.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/ai/chat/history/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final messages = (data['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList();
      return messages;
    }
    throw Exception('Failed to get chat history');
  }

  // Get user's active sessions
  Future<List<ChatSession>> getUserSessions() async {
    final token = await AuthUtils.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/ai/chat/sessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final sessions = (data['sessions'] as List)
          .map((s) => ChatSession.fromJson(s))
          .toList();
      return sessions;
    }
    throw Exception('Failed to get user sessions');
  }

  // End chat session
  Future<void> endChatSession(String sessionId) async {
    final token = await AuthUtils.getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat/end/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to end chat session');
    }
  }
}
