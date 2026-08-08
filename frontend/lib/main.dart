import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/presentation/chat_screen.dart';

void main() => runApp(const ProviderScope(child: WhisperChatApp()));

class WhisperChatApp extends StatelessWidget {
  const WhisperChatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Whisper Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const ChatScreen(),
      );
}
