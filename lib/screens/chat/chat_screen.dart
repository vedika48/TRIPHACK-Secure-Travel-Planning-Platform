import 'package:flutter/material.dart';
import '../../services/session_manager.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final SessionManager _sessionManager = SessionManager();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _sessionInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      await _sessionManager.loadSession();

      if (_sessionManager.currentSession == null) {
        await _sessionManager.initializeSession();
      }

      setState(() {
        _sessionInitialized = true;
      });

      // Add welcome message
      _addWelcomeMessage();

    } catch (e) {
      print('Session initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: 'Hello! I\'m your Travel Assistant. How can I help you with your travel plans today?',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Travel Assistant'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSession,
            tooltip: 'Refresh Session',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionInfo(),
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Chat Session...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    if (_sessionManager.currentSession == null) return Container();

    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.security, size: 16, color: Colors.blue.shade700),
          SizedBox(width: 8),
          Text(
            'Session: ${_sessionManager.currentSession!.sessionKey.substring(0, 8)}...',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.info, size: 16),
            onPressed: _showSessionInfo,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return _messages.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Start a conversation about your travel plans!',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text('Assistant is typing...'),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
            child: Icon(Icons.send),
            mini: true,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading || _sessionManager.currentSession == null) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _apiService.sendMessage(
        text,
        _sessionManager.currentSession!.sessionKey,
      );

      final assistantMessage = ChatMessage(
        text: response['message'],
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
      });

      // Update session activity
      await _sessionManager.updateSessionActivity();

    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshSession() async {
    setState(() => _isLoading = true);
    try {
      await _sessionManager.clearSession();
      await _sessionManager.initializeSession();
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session refreshed successfully')),
      );
    } catch (e) {
      _showError('Failed to refresh session: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSessionInfo() async {
    final health = await _sessionManager.healthCheck();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Information'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('API Status: ${health['api_healthy'] ? 'Healthy' : 'Unhealthy'}'),
            Text('Session Valid: ${health['session_valid'] ? 'Yes' : 'No'}'),
            Text('User ID: ${health['user_id']}'),
            Text('Session Key: ${health['session_key']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ChatMessage and ChatBubble classes remain the same as previous version
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              child: Icon(Icons.smart_toy, size: 16),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue.shade600 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Text(
                message.text,
                style: TextStyle(color: message.isUser ? Colors.white : Colors.black87),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
          ],
        ],
      ),
    );
  }
}