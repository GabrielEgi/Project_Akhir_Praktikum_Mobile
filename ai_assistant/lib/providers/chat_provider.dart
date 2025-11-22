import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();
  final Uuid _uuid = const Uuid();

  List<Chat> _chats = [];
  Chat? _currentChat;
  List<Message> _currentMessages = [];
  bool _isLoading = false;
  String? _error;

  List<Chat> get chats => _chats;
  Chat? get currentChat => _currentChat;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _chats = _dbHelper.getAllChats();
    notifyListeners();
  }

  Future<void> createNewChat() async {
    try {
      final chat = Chat(
        id: _uuid.v4(),
        title: 'Obrolan Baru',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbHelper.createChat(chat);
      _chats.insert(0, chat);
      _currentChat = chat;
      _currentMessages = [];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create chat: $e';
      notifyListeners();
    }
  }

  void selectChat(String chatId) {
    _isLoading = true;
    notifyListeners();

    final chat = _dbHelper.getChatById(chatId);
    if (chat != null) {
      _currentChat = chat;
      _currentMessages = _dbHelper.getMessagesByChatId(chatId);
      _error = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (_currentChat == null) {
      await createNewChat();
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userMessage = Message(
        id: _uuid.v4(),
        chatId: _currentChat!.id,
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

      await _dbHelper.createMessage(userMessage);
      _currentMessages.add(userMessage);
      notifyListeners();

      final aiResponse = await _apiService.sendMessage(
        messages: _currentMessages,
      );

      final assistantMessage = Message(
        id: _uuid.v4(),
        chatId: _currentChat!.id,
        content: aiResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      await _dbHelper.createMessage(assistantMessage);
      _currentMessages.add(assistantMessage);

      if (_currentMessages.length == 2) {
        final title = await _apiService.generateChatTitle(content);
        final updatedChat = _currentChat!.copyWith(
          title: title,
          updatedAt: DateTime.now(),
        );
        await _dbHelper.updateChat(updatedChat);
        _currentChat = updatedChat;

        final index = _chats.indexWhere((c) => c.id == updatedChat.id);
        if (index != -1) {
          _chats[index] = updatedChat;
        }
      } else {
        final updatedChat = _currentChat!.copyWith(updatedAt: DateTime.now());
        await _dbHelper.updateChat(updatedChat);
        _currentChat = updatedChat;
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to send message: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _dbHelper.deleteChat(chatId);
      _chats.removeWhere((chat) => chat.id == chatId);

      if (_currentChat?.id == chatId) {
        _currentChat = null;
        _currentMessages = [];
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete chat: $e';
      notifyListeners();
    }
  }

  Future<void> updateChatTitle(String chatId, String newTitle) async {
    try {
      final chat = _chats.firstWhere((c) => c.id == chatId);
      final updatedChat = chat.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateChat(updatedChat);

      final index = _chats.indexWhere((c) => c.id == chatId);
      if (index != -1) {
        _chats[index] = updatedChat;
      }

      if (_currentChat?.id == chatId) {
        _currentChat = updatedChat;
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update chat title: $e';
      notifyListeners();
    }
  }

  void clearCurrentChat() {
    _currentChat = null;
    _currentMessages = [];
    notifyListeners();
  }
}
