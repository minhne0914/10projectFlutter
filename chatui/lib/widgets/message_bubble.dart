import 'package:flutter/material.dart';
import '../models/message.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message msg;
  final bool showAvatar;
  final bool showTail;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.msg,
    this.showAvatar = false,
    this.showTail = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = msg.sender == Sender.me;
    final bubbleColor = isMe
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerLow;

    final textColor = isMe
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurface;

    final radius = 18.0;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 4 : radius)),
      bottomRight: Radius.circular(isMe ? (showTail ? 4 : radius) : 18),
    );

    final timeStr = DateFormat('HH:mm').format(msg.time);

    final statusIcon = switch (msg.status) {
      MsgStatus.sending => const Icon(Icons.schedule, size: 14),
      MsgStatus.sent => const Icon(Icons.check, size: 14),
      MsgStatus.delivered => const Icon(Icons.done_all, size: 14),
      MsgStatus.read => const Icon(Icons.done_all, size: 14, color: Colors.blueAccent),
    };

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: InkWell(
        borderRadius: borderRadius,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bubbleColor, borderRadius: borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  msg.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor.withOpacity(0.8)),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    statusIcon,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Avatar cho bên đối phương
    final avatar = showAvatar && !isMe
        ? const CircleAvatar(radius: 14, child: Text('A'))
        : const SizedBox(width: 28, height: 28);

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 56 : 12,
        right: isMe ? 12 : 56,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            SizedBox(width: 32, child: Center(child: avatar)),
            const SizedBox(width: 6),
          ],
          bubble,
          if (isMe) const SizedBox(width: 6),
          if (isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }
}
