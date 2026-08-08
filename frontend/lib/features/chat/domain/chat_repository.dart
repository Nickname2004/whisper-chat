import 'message.dart';

abstract interface class ChatRepository {
  Stream<List<Message>> messages();
  Future<void> sendMessage(String text);
  Future<void> dispose();
}
