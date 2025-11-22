import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat.dart';
import '../models/message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String _chatsBox = 'chats';
  static const String _messagesBox = 'messages';

  DatabaseHelper._init();

  Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ChatAdapter());
    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(MessageRoleAdapter());

    await Hive.openBox<Chat>(_chatsBox);
    await Hive.openBox<Message>(_messagesBox);
  }

  Box<Chat> get _chatBox => Hive.box<Chat>(_chatsBox);
  Box<Message> get _messageBox => Hive.box<Message>(_messagesBox);

  // CRUD Operations for Chats
  Future<Chat> createChat(Chat chat) async {
    await _chatBox.put(chat.id, chat);
    return chat;
  }

  List<Chat> getAllChats() {
    final chats = _chatBox.values.toList();
    chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return chats;
  }

  Chat? getChatById(String id) {
    return _chatBox.get(id);
  }

  Future<void> updateChat(Chat chat) async {
    await _chatBox.put(chat.id, chat);
  }

  Future<void> deleteChat(String id) async {
    await _chatBox.delete(id);
    // Delete associated messages
    final messagesToDelete =
        _messageBox.values.where((msg) => msg.chatId == id).toList();
    for (final msg in messagesToDelete) {
      await _messageBox.delete(msg.id);
    }
  }

  // CRUD Operations for Messages
  Future<Message> createMessage(Message message) async {
    await _messageBox.put(message.id, message);
    return message;
  }

  List<Message> getMessagesByChatId(String chatId) {
    final messages =
        _messageBox.values.where((msg) => msg.chatId == chatId).toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<void> deleteMessage(String id) async {
    await _messageBox.delete(id);
  }

  Future<void> deleteMessagesByChatId(String chatId) async {
    final messagesToDelete =
        _messageBox.values.where((msg) => msg.chatId == chatId).toList();
    for (final msg in messagesToDelete) {
      await _messageBox.delete(msg.id);
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}
