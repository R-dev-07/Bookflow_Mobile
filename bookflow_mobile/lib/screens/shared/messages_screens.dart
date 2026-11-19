import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../utils.dart';
import '../../widgets/common.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: FutureView<List<Conversation>>(
        cacheKey: 'conversations',
        skeleton: SkeletonKind.rows,
        load: api.conversations,
        builder: (context, items, reload) {
          if (items.isEmpty) {
            return RefreshList(
              onRefresh: reload,
              children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No conversations yet',
                  subtitle: 'Chats start from a booking request.',
                ),
              ],
            );
          }
          return RefreshList(
            onRefresh: reload,
            children: [
              for (final c in items)
                AppCard(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(bookingItemId: c.bookingItemId, title: c.title),
                      ),
                    );
                    reload();
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        child: Text(c.otherName.isEmpty ? '?' : c.otherName[0].toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w700),
                            ),
                            Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cs.primary, fontSize: 12),
                            ),
                            Text(
                              c.lastMessage ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeAgo(c.lastAt), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                          if (c.unread > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${c.unread}',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Chat for one booking item. Refreshes every few seconds (polling) while open.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.bookingItemId, required this.title});
  final String bookingItemId, title;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  ChatThread? _thread;
  String? _error;
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final t = await context.read<Api>().thread(widget.bookingItemId);
      if (mounted)
        setState(() {
          _thread = t;
          _error = null;
        });
    } catch (e) {
      if (mounted && _thread == null) setState(() => _error = e.toString());
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<Api>().sendMessage(widget.bookingItemId, text);
      _ctrl.clear();
      await _refresh();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = _thread;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t?.otherName ?? widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.title,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: t == null
                ? (_error != null
                      ? ErrorView(message: _error!, onRetry: _refresh)
                      : const Center(child: CircularProgressIndicator()))
                : t.messages.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Say hello',
                    subtitle: 'Ask a question or share details about the event.',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: t.messages.length,
                    itemBuilder: (context, i) {
                      final m = t.messages[t.messages.length - 1 - i];
                      return Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: m.mine ? cs.primary : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(m.mine ? 18 : 4),
                              bottomRight: Radius.circular(m.mine ? 4 : 18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m.content, style: TextStyle(color: m.mine ? cs.onPrimary : cs.onSurface)),
                              const SizedBox(height: 2),
                              Text(
                                fmtTime(m.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: (m.mine ? cs.onPrimary : cs.onSurfaceVariant).withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: fieldDecoration('Message')
                          .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
