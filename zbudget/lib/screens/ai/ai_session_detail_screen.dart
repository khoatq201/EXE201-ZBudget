import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_chat_service.dart';
import '../../models/ai_models.dart';
import '../../utils/theme_extensions.dart';

class AiSessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const AiSessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  State<AiSessionDetailScreen> createState() => _AiSessionDetailScreenState();
}

class _AiSessionDetailScreenState extends State<AiSessionDetailScreen> {
  final AiChatService _aiService = AiChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _aiService.getChatHistory(widget.sessionId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể tải chi tiết cuộc trò chuyện: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sessionTitle, style: const TextStyle(fontSize: 16)),
            Text(
              '${_messages.length} tin nhắn',
              style: TextStyle(
                fontSize: 12,
                color: context.settingsItemSubtitleColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessionDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
          ? Center(
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
                    'Không có tin nhắn nào',
                    style: TextStyle(
                      color: context.settingsItemSubtitleColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? context.colorScheme.primary : context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser
                ? context.colorScheme.primary.withOpacity(0.3)
                : context.cardBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            else
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontSize: 14,
                  ),
                  h1: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 12,
                  color: isUser
                      ? Colors.white.withOpacity(0.7)
                      : context.settingsItemSubtitleColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : context.settingsItemSubtitleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
