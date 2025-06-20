import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_page.dart';
import 'message_detailed.dart';

class InboxPage extends StatefulWidget {
  final String mobile;

  const InboxPage({super.key, required this.mobile});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<dynamic> messages = [];
  String? errorMessage; // Add error message state

  // Helper to format date string
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
  void initState() {
    super.initState();
    _fetchMessages();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
        _fetchMessages(); // Refresh inbox
      }
    });
  }

  Future<void> _fetchMessages() async {
    setState(() {
      errorMessage = null; // Reset error before fetching
    });
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/messages/${widget.mobile}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            messages = data;
            errorMessage = null;
          });
        } else {
          setState(() {
            messages = [];
            errorMessage = "Invalid data format from server.";
          });
        }
      } else {
        setState(() {
          messages = [];
          errorMessage = "Failed to load messages (status ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        messages = [];
        errorMessage = "Error loading messages: $e";
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobile');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => RegisterPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📥 Inbox"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMessages,
        child: errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 400,
                    child: Center(child: Text(errorMessage!)),
                  ),
                ],
              )
            : messages.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 400,
                        child: Center(child: Text("No messages yet")),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final messageText = msg['content']?.toString() ?? "(No message)";
                      final priorityText = msg['priority']?.toString() ?? "-";
                      final expiryText = formatDate(msg['expiry']?.toString());
                      final groupText = msg['group']?.toString() ?? "-";
                      final timestampText = formatDate(msg['timestamp']?.toString());
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(messageText),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Group: $groupText"),
                              Text("Priority: $priorityText"),
                              Text("Sent: $timestampText"),
                            ],
                          ),
                          trailing: Text("📅 $expiryText"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessageDetailPage(message: msg),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
