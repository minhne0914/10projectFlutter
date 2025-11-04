import 'package:flutter/material.dart';
import 'models/message.dart';
import 'widgets/message_bubble.dart';
import 'widgets/date_separator.dart';

void main() {
  runApp(const ChatUICloneApp());
}

class ChatUICloneApp extends StatelessWidget {
  const ChatUICloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1A73E8);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat UI Clone',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Message> _messages = [];
  bool _otherTyping = false;

  @override
  void initState() {
    super.initState();
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    _messages.addAll([
      Message(id: '1', sender: Sender.other, text: 'Hey Min! 👋', time: now.subtract(const Duration(minutes: 58))),
      Message(id: '2', sender: Sender.me, text: 'Hello! How’s it going?', time: now.subtract(const Duration(minutes: 57)), status: MsgStatus.read),
      Message(id: '3', sender: Sender.other, text: 'Wanna try the new coffee place later?', time: now.subtract(const Duration(minutes: 55))),
      Message(id: '4', sender: Sender.me, text: 'Sounds great. 5pm?', time: now.subtract(const Duration(minutes: 54)), status: MsgStatus.delivered),
      Message(id: '5', sender: Sender.other, text: 'Perfect ☕️', time: now.subtract(const Duration(minutes: 53))),
    ]);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msg = Message(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sender: Sender.me,
      text: text,
      time: DateTime.now(),
      status: MsgStatus.sending,
    );

    setState(() => _messages.add(msg));
    _scrollToBottom();

    // Giả lập gửi xong -> delivered -> read
    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() => msg.status = MsgStatus.sent);
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => msg.status = MsgStatus.delivered);
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => msg.status = MsgStatus.read);
    });

    // Giả lập bên kia trả lời + typing
    setState(() => _otherTyping = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _otherTyping = false;
        _messages.add(
          Message(
            id: DateTime.now().add(const Duration(milliseconds: 1)).microsecondsSinceEpoch.toString(),
            sender: Sender.other,
            text: 'Got it: "$text"',
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            const BackButton(),
            const CircleAvatar(radius: 16, child: Text('A')),
          ],
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alice', style: TextStyle(fontSize: 16)),
          Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: const [
        Icon(Icons.call_outlined),
        SizedBox(width: 12),
        Icon(Icons.videocam_outlined),
        SizedBox(width: 12),
        Icon(Icons.more_vert),
        SizedBox(width: 6),
      ],
    );

    final items = _buildItemsWithSeparators(_messages);

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length + (_otherTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_otherTyping && index == items.length) {
                  return const _TypingIndicator();
                }
                final item = items[index];
                return item;
              },
            ),
          ),
          const Divider(height: 1),
          _InputBar(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  // Chèn DateSeparator khi ngày thay đổi
  List<Widget> _buildItemsWithSeparators(List<Message> msgs) {
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (int i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final showAvatar = i == msgs.length - 1 || msgs[i + 1].sender != m.sender;
      final showTail = showAvatar;

      final date = DateUtils.dateOnly(m.time);
      if (lastDate == null || date != lastDate) {
        widgets.add(DateSeparator(date: m.time));
        lastDate = date;
      }
      widgets.add(MessageBubble(msg: m, showAvatar: showAvatar, showTail: showTail, onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message "${m.text}" long-pressed')));
      }));
    }
    return widgets;
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          const CircleAvatar(radius: 12, child: Text('A', style: TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Dot(), SizedBox(width: 4), _Dot(), SizedBox(width: 4), _Dot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 50),
      ]).animate(_c),
      child: const CircleAvatar(radius: 3),
    );
  }
}
