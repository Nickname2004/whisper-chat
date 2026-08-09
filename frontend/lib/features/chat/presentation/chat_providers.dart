import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/websocket_chat_repository.dart';
import '../domain/chat_repository.dart';
import '../domain/message.dart';

const _endpoint = String.fromEnvironment('WS_URL', defaultValue: 'ws://localhost:8080/ws');
const currentUserId = String.fromEnvironment('USER_ID', defaultValue: 'local-user');

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repository = WebSocketChatRepository(endpoint: _endpoint, userId: currentUserId);
  ref.onDispose(repository.dispose);
  return repository;
});

final messagesProvider = StreamProvider<List<Message>>(
  (ref) => ref.watch(chatRepositoryProvider).messages(),
);

class ComposerController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> send(String text) async {
    if (state || text.trim().isEmpty) return;
    state = true;
    try {
      await ref.read(chatRepositoryProvider).sendMessage(text);
    } finally {
      state = false;
    }
  }
}

final composerProvider = NotifierProvider<ComposerController, bool>(ComposerController.new);
