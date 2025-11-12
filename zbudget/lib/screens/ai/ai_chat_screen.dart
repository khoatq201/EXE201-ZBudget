import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_chat_service.dart';
import '../../models/ai_models.dart';
import '../../utils/theme_extensions.dart';

class AiChatScreen extends StatefulWidget {
  final String? existingSessionId;

  const AiChatScreen({super.key, this.existingSessionId});

  // Factory constructor để load session cũ
  factory AiChatScreen.fromSession(String sessionId) {
    return AiChatScreen(existingSessionId: sessionId);
  }

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  bool _hasShownWelcome = false;
  String? _sessionId;
  String _streamingMessage = '';
  late AnimationController _streamingAnimation;
  final AiChatService _aiService = AiChatService();

  @override
  void initState() {
    super.initState();
    _streamingAnimation = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    if (widget.existingSessionId != null) {
      _loadExistingSession();
    } else {
      _initializeChat();
    }
  }

  @override
  void dispose() {
    _streamingAnimation.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      _sessionId = await _aiService.startChatSession();

      // Try to load chat history first
      try {
        await _loadChatHistory();
        // If history is empty, show welcome message
        if (_messages.isEmpty && !_hasShownWelcome) {
          _addWelcomeMessage();
          _hasShownWelcome = true;
        }
      } catch (e) {
        // If loading fails (empty session), show welcome message
        if (!_hasShownWelcome) {
          _addWelcomeMessage();
          _hasShownWelcome = true;
        }
      }
    } catch (e) {
      _showError('Không thể khởi tạo chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingSession() async {
    setState(() => _isLoading = true);
    try {
      _sessionId = widget.existingSessionId;
      await _aiService.loadExistingSession(_sessionId!);
      await _loadChatHistory();
    } catch (e) {
      _showError('Không thể tải lịch sử chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChatHistory() async {
    if (_sessionId == null) return;

    try {
      final messages = await _aiService.getChatHistory(_sessionId!);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
      // If loading fails, show welcome message
      if (!_hasShownWelcome) {
        _addWelcomeMessage();
        _hasShownWelcome = true;
      }
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: '''👋 **Chào mừng bạn đến với ZBudget AI!**

Tôi là trợ lý tài chính thông minh của bạn. Tôi có thể giúp bạn:

💰 **Phân tích chi tiêu** - Hiểu rõ thói quen chi tiêu
📊 **Lập ngân sách** - Tạo kế hoạch tài chính hiệu quả  
🎯 **Đặt mục tiêu tiết kiệm** - Lên kế hoạch cho tương lai
📈 **Tư vấn đầu tư** - Gợi ý cách tăng trưởng tài sản
🔍 **Phát hiện bất thường** - Cảnh báo chi tiêu bất thường

Hãy bắt đầu bằng cách hỏi tôi về tình hình tài chính của bạn! 😊''',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    // Scroll to bottom để hiển thị welcome message
    _scrollToBottom();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _sessionId == null) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isStreaming = true;
      _streamingMessage = '';
    });

    _scrollToBottom();

    try {
      final stream = _aiService.sendMessageWithStreaming(_sessionId!, text);

      await for (var chunk in stream) {
        // Debug: Log chunk để kiểm tra
        print('Received chunk: $chunk');

        setState(() {
          _streamingMessage += chunk;
        });
        _scrollToBottom();

        // Thêm delay nhỏ để tạo hiệu ứng typing tự nhiên
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Add complete AI message
      final aiMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: _streamingMessage,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isStreaming = false;
        _streamingMessage = '';
      });
    } catch (e) {
      setState(() => _isStreaming = false);
      _showError('Lỗi khi gửi tin nhắn: $e');
    }
  }

  Future<void> _startNewChat() async {
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu cuộc trò chuyện mới?'),
        content: const Text(
          'Cuộc trò chuyện hiện tại sẽ được lưu vào lịch sử. Bạn có muốn bắt đầu một cuộc trò chuyện mới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bắt đầu mới'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Clear active session and create new one
      await _aiService.clearActiveSession();
      _sessionId = await _aiService.startChatSession(forceNew: true);

      // Clear messages and show welcome
      setState(() {
        _messages.clear();
        _hasShownWelcome = false;
        _isLoading = false;
      });

      _addWelcomeMessage();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể tạo cuộc trò chuyện mới: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colorScheme.primary,
                    context.headerGradientEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tư vấn tài chính', style: TextStyle(fontSize: 16)),
                Text('ZBudget Assistant', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          // New chat button
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions
          _buildQuickActions(),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isStreaming) {
                        return _buildStreamingMessage();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AiChatService.quickActions.length,
        itemBuilder: (context, index) {
          final action = AiChatService.quickActions[index];
          return _buildQuickActionCard(action);
        },
      ),
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: ElevatedButton(
        onPressed: _isStreaming ? null : () => _sendMessage(action.message),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 28),
            const SizedBox(height: 8),
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
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
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                  strong: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStreamingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streaming text với animation
            AnimatedBuilder(
              animation: _streamingAnimation,
              builder: (context, child) {
                return Text(
                  _streamingMessage + '|',
                  style: TextStyle(
                    color: context.settingsItemTitleColor,
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Typing indicator với animation
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      context.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI đang phân tích...',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.settingsItemSubtitleColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isStreaming, // Disable khi đang streaming
              decoration: InputDecoration(
                hintText: _isStreaming
                    ? 'AI đang trả lời...'
                    : 'Hỏi AI về tài chính...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: _isStreaming ? null : _sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _isStreaming
                ? null
                : () => _sendMessage(_messageController.text),
            backgroundColor: _isStreaming
                ? Colors.grey.withOpacity(0.3)
                : context.colorScheme.primary,
            child: _isStreaming
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
