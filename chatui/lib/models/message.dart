enum Sender { me, other }
enum MsgStatus { sending, sent, delivered, read }

class Message {
  final String id;
  final Sender sender;
  final String text;
  final DateTime time;
  MsgStatus status; // mutable để demo chuyển trạng thái

  Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.status = MsgStatus.sent,
  });
}
