import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageDetailPage extends StatelessWidget {
  final Map<String, dynamic> message;

  const MessageDetailPage({super.key, required this.message});

  String formatDate(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageText = message['message']?.toString() ?? "(No message)";
    final priority = message['priority']?.toString() ?? "-";
    final visibleUpto = formatDate(message['visible_upto']?.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text("📨 Message Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Message", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(messageText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Priority: $priority", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Visible Until: $visibleUpto", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
