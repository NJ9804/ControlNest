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
import 'package:hive_flutter/hive_flutter.dart';

class InboxPage extends StatefulWidget {
  final String mobile;

  const InboxPage({super.key, required this.mobile});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with TickerProviderStateMixin {
  List<dynamic> messages = [];
  String? errorMessage;
  bool isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Box hiveBox;

  // Helper to format date string
  String formatDate(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString);
      final dtIst = dt.add(const Duration(hours: 5, minutes: 30));
      return DateFormat('yyyy-MM-dd HH:mm').format(dtIst);
    } catch (_) {
      return isoString;
    }
  }

  // Helper to format timestamp in a user-friendly way
  String formatTimestamp(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString);
      final dtIst = dt.add(const Duration(hours: 5, minutes: 30));
      final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dtIst.year, dtIst.month, dtIst.day);
      final diff = today.difference(msgDay).inDays;
      String dayStr;
      if (diff == 0) {
        dayStr = "Today";
      } else if (diff == 1) {
        dayStr = "Yesterday";
      } else {
        dayStr = DateFormat('d MMM yyyy').format(dtIst);
      }
      String timeStr = DateFormat('h:mm a').format(dtIst);
      return "$dayStr, $timeStr";
    } catch (_) {
      return isoString;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    hiveBox = Hive.box('messages');
    _loadMessagesFromHive();
    _fetchMessages();
    _setupFirebaseMessaging();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  void _setupFirebaseMessaging() {
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

  void _loadMessagesFromHive() {
    final cached = hiveBox.get(widget.mobile);
    if (cached != null && cached is List) {
      setState(() {
        messages = List<Map<String, dynamic>>.from(
          cached.map((e) => Map<String, dynamic>.from(e)),
        );
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      // Do NOT clear messages here
    });
    try {
      final response = await http.get(
        Uri.parse("https://notification-j802.onrender.com/api/messages/${widget.mobile}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Sort by priority and timestamp (latest first)
          data.sort((a, b) {
            int priorityValue(String? p) {
              switch ((p ?? '').toLowerCase()) {
                case 'high':
                  return 2;
                case 'medium':
                  return 1;
                default:
                  return 0;
              }
            }
            int pA = priorityValue(a['priority']?.toString());
            int pB = priorityValue(b['priority']?.toString());
            if (pA != pB) return pB.compareTo(pA); // High first
            // If same priority, sort by timestamp descending
            DateTime tA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(1970);
            DateTime tB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(1970);
            return tB.compareTo(tA);
          });
          setState(() {
            messages = data;
            errorMessage = null;
            isLoading = false;
          });
          // Save to Hive for offline use
          hiveBox.put(widget.mobile, data);
        } else {
          setState(() {
            errorMessage = "Invalid data format from server.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              "Failed to load messages (status {response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error loading messages: $e";
        isLoading = false;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: _buildDrawer(colorScheme),
      appBar: _buildAppBar(colorScheme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Messages List
            Expanded(child: _buildMessagesList(colorScheme)),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Inbox",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            "${messages.length} messages",
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ColorScheme colorScheme) {
    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "NotifyHub",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.mobile,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.inbox,
                  title: "Inbox",
                  isSelected: true,
                  colorScheme: colorScheme,
                  onTap: () => Navigator.pop(context),
                ),
               
                const Divider(height: 32),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: "Settings",
                  colorScheme: colorScheme,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: "Help",
                  colorScheme: colorScheme,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                "Logout",
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: _logout,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMessagesList(ColorScheme colorScheme) {
    return ValueListenableBuilder(
      valueListenable: hiveBox.listenable(keys: [widget.mobile]),
      builder: (context, Box box, _) {
        final cached = box.get(widget.mobile);
        final localMessages = (cached != null && cached is List)
            ? List<Map<String, dynamic>>.from(
                cached.map((e) => Map<String, dynamic>.from(e)),
              )
            : [];
        // Show error if there is no data at all
        if (errorMessage != null && localMessages.isEmpty) {
          return _buildErrorState(colorScheme);
        }
        if (localMessages.isEmpty) {
          return _buildEmptyState(colorScheme);
        }
        return Column(
          children: [
            if (isLoading)
              LinearProgressIndicator(
                minHeight: 3,
                color: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer.withOpacity(0.2),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchMessages,
                color: colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: localMessages.length,
                  itemBuilder: (context, index) {
                    final msg = localMessages[index];
                    return _buildMessageItem(msg, colorScheme, index);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageItem(
    Map<String, dynamic> msg,
    ColorScheme colorScheme,
    int index,
  ) {
    final messageText = msg['content']?.toString() ?? "(No message)";
    final priorityText = msg['priority']?.toString() ?? "Normal";
    final expiryText = formatDate(msg['expiry']?.toString());
    final groupText = msg['group']?.toString() ?? "General";
    final timestampText = formatTimestamp(msg['timestamp']?.toString());

    // Determine priority color
    Color priorityColor = colorScheme.onSurface.withOpacity(0.6);
    if (priorityText.toLowerCase() == 'high') {
      priorityColor = colorScheme.error;
    } else if (priorityText.toLowerCase() == 'medium') {
      priorityColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessageDetailPage(message: msg),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Group Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        groupText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Priority Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priorityText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Timestamp
                    Text(
                      timestampText,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message Content
                Text(
                  messageText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Footer Row
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Expires: $expiryText",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 60,
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You'll see your notifications here when they arrive",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.error_outline,
              size: 60,
              color: colorScheme.error.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Something went wrong",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchMessages,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return FloatingActionButton(
      onPressed: _fetchMessages,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      child: const Icon(Icons.refresh),
    );
  }
}
