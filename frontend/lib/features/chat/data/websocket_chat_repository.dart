import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/chat_repository.dart';
import '../domain/message.dart';

class WebSocketChatRepository implements ChatRepository {
  WebSocketChatRepository({required String endpoint, required this.userId})
      : _channel = WebSocketChannel.connect(Uri.parse('$endpoint?user_id=$userId'));

  final String userId;
  final WebSocketChannel _channel;
  final _messages = <Message>[];
  final _controller = StreamController<List<Message>>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  @override
  Stream<List<Message>> messages() {
    _subscription ??= _channel.stream.listen(
      (raw) {
        final event = jsonDecode(raw as String) as Map<String, dynamic>;
        if (event['type'] == 'message') {
          final message = Message.fromJson(event['message'] as Map<String, dynamic>);
          if (_messages.every((item) => item.id != message.id)) {
            _messages.add(message);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _controller.add(List.unmodifiable(_messages));
          }
        }
      },
      onError: _controller.addError,
      onDone: _controller.close,
    );
    return _controller.stream;
  }

  @override
  Future<void> sendMessage(String text) async {
    _channel.sink.add(jsonEncode({'type': 'message', 'text': text.trim()}));
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _channel.sink.close();
    await _controller.close();
  }
}
