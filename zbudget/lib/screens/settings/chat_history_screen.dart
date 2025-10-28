import 'package:flutter/material.dart';
import '../../services/ai_chat_service.dart';
import '../../models/ai_models.dart';
import '../../utils/theme_extensions.dart';
import '../ai/ai_chat_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final AiChatService _aiService = AiChatService();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sessions = await _aiService.getUserSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Không thể tải lịch sử chat: $e';
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hôm qua ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildSessionItem(ChatSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.colorScheme.primary,
          child: const Icon(Icons.chat, color: Colors.white, size: 20),
        ),
        title: Text(
          'Chat ${session.sessionId.substring(0, 8)}...',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.settingsItemTitleColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${session.messageCount} tin nhắn • ${_formatDate(session.lastMessageAt)}',
              style: TextStyle(
                color: context.settingsItemSubtitleColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: context.settingsItemSubtitleColor,
        ),
        onTap: () => _openSession(session.sessionId),
      ),
    );
  }

  void _openSession(String sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiChatScreen.fromSession(sessionId),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: context.settingsItemSubtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử chat nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: context.settingsItemTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu chat với AI để tạo lịch sử',
            style: TextStyle(color: context.settingsItemSubtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: context.settingsItemTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Không thể tải lịch sử chat',
            style: TextStyle(color: context.settingsItemSubtitleColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSessions,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.background,
      appBar: AppBar(
        title: const Text('Lịch sử Chat AI'),
        backgroundColor: context.headerGradientStart,
        foregroundColor: context.headerTextColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSessions),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải lịch sử chat...',
                    style: TextStyle(color: context.settingsItemSubtitleColor),
                  ),
                ],
              ),
            )
          : _error != null
          ? _buildErrorState()
          : _sessions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: context.colorScheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _sessions.length,
                itemBuilder: (context, index) =>
                    _buildSessionItem(_sessions[index]),
              ),
            ),
    );
  }
}
