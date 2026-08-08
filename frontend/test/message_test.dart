import 'package:flutter_test/flutter_test.dart';
import 'package:whisper_chat/features/chat/domain/message.dart';

void main() {
  test('formats timestamp using 24-hour time', () {
    final message = Message(id: '1', text: 'test', senderId: 'user', timestamp: DateTime(2026, 8, 8, 7, 5));
    expect(message.formattedTime, '07:05');
  });
}
