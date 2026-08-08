import 'package:flutter/foundation.dart';

@immutable
class Message {
  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        text: json['text'] as String,
        senderId: json['senderId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      );
}
