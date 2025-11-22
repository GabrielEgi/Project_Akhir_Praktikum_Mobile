import 'package:hive/hive.dart';

enum MessageRole { user, assistant, system }

class MessageRoleAdapter extends TypeAdapter<MessageRole> {
  @override
  final int typeId = 1;

  @override
  MessageRole read(BinaryReader reader) {
    final index = reader.readByte();
    return MessageRole.values[index];
  }

  @override
  void write(BinaryWriter writer, MessageRole obj) {
    writer.writeByte(obj.index);
  }
}

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 2;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      chatId: fields[1] as String,
      content: fields[2] as String,
      role: fields[3] as MessageRole,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.timestamp);
  }
}

class Message {
  final String id;
  final String chatId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.chatId,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  Message copyWith({
    String? id,
    String? chatId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
