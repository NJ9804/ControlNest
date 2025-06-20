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
    final messageText = message['content']?.toString() ?? "(No message)";
    final priority = message['priority']?.toString() ?? "-";
    final expiry = formatDate(message['expiry']?.toString());
    final group = message['group']?.toString() ?? "-";
    final timestamp = formatDate(message['timestamp']?.toString());

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
            Text("Group: $group", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Priority: $priority", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Sent: $timestamp", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Visible Until: $expiry", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
