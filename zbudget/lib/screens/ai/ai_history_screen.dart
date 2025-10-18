import 'package:flutter/material.dart';
import '../../services/ai_chat_service.dart';
import '../../models/ai_models.dart';
import '../../utils/theme_extensions.dart';
import 'ai_chat_screen.dart';
import 'ai_session_detail_screen.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  final AiChatService _aiService = AiChatService();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _aiService.getUserSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể tải lịch sử chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử AI Chat'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSessions),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc trò chuyện...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Sessions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSessionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSessionsList() {
    final filteredSessions = _sessions.where((session) {
      if (_searchQuery.isEmpty) return true;
      return session.sessionId.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          session.messages.any(
            (msg) =>
                msg.content.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
    }).toList();

    if (filteredSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: context.settingsItemSubtitleColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Chưa có cuộc trò chuyện nào'
                  : 'Không tìm thấy kết quả',
              style: TextStyle(
                color: context.settingsItemSubtitleColor,
                fontSize: 16,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Bắt đầu cuộc trò chuyện với AI',
                style: TextStyle(
                  color: context.settingsItemSubtitleColor,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    final lastMessage = session.messages.isNotEmpty
        ? session.messages.last
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colorScheme.primary, context.headerGradientEnd],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),
        title: Text(
          'Chat Session ${session.sessionId.substring(0, 8)}...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastMessage != null) ...[
              Text(
                lastMessage.content.length > 50
                    ? '${lastMessage.content.substring(0, 50)}...'
                    : lastMessage.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Icon(
                  Icons.message,
                  size: 12,
                  color: context.settingsItemSubtitleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.messageCount} tin nhắn',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: context.settingsItemSubtitleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(session.lastMessageAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: session.isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hoạt động',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiSessionDetailScreen(
                sessionId: session.sessionId,
                sessionTitle:
                    'Chat Session ${session.sessionId.substring(0, 8)}...',
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
