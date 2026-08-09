import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/message.dart';
import 'chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() { _input.dispose(); _scroll.dispose(); super.dispose(); }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    ref.listen(messagesProvider, (_, next) { if (next.hasValue) _scrollToBottom(); });
    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Whisper Chat'), SizedBox(width: 8), Icon(Icons.circle, size: 11, color: Colors.greenAccent),
        ]),
        centerTitle: true,
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: Column(children: [
        Expanded(child: messages.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: error),
          data: (items) => items.isEmpty ? const Center(child: Text('No messages yet. Start whispering...')) : ListView.builder(
            controller: _scroll, padding: const EdgeInsets.all(16), itemCount: items.length,
            itemBuilder: (_, index) => _MessageBubble(message: items[index]),
          ),
        )),
        _Composer(input: _input),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Message message;
  @override
  Widget build(BuildContext context) {
    final isMine = message.senderId == currentUserId;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320), margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
        decoration: BoxDecoration(color: isMine ? colors.primary : colors.surfaceContainerHigh, borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMine ? 18 : 4), bottomRight: Radius.circular(isMine ? 4 : 18),
        )),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Align(alignment: Alignment.centerLeft, child: Text(message.text, style: TextStyle(color: isMine ? colors.onPrimary : colors.onSurface))),
          const SizedBox(height: 4), Text(message.formattedTime, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isMine ? colors.onPrimary.withValues(alpha: .75) : colors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _Composer extends ConsumerWidget {
  const _Composer({required this.input});
  final TextEditingController input;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(composerProvider);
    Future<void> send() async { final text = input.text; await ref.read(composerProvider.notifier).send(text); if (text.trim().isNotEmpty) input.clear(); }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: input,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => send(),
                decoration: const InputDecoration(
                  hintText: 'Type a whisper...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : send,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error}); final Object error;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_outlined, size: 42), const SizedBox(height: 12), const Text('Could not connect to Whisper Chat.'), const SizedBox(height: 8), Text('$error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 12), FilledButton.tonal(onPressed: () => ref.invalidate(messagesProvider), child: const Text('Retry')),
  ])));
}
