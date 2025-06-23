import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageDetailPage extends StatefulWidget {
  final Map<String, dynamic> message;

  const MessageDetailPage({super.key, required this.message});

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String formatDate(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  String formatRelativeDate(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays > 0) {
        return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
      } else if (diff.inHours > 0) {
        return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
      } else if (diff.inMinutes > 0) {
        return "${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago";
      } else {
        return "Just now";
      }
    } catch (_) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final messageText = widget.message['content']?.toString() ?? "(No message)";
    final priority = widget.message['priority']?.toString() ?? "Normal";
    final expiry = formatDate(widget.message['expiry']?.toString());
    final group = widget.message['group']?.toString() ?? "General";
    final timestamp = formatDate(widget.message['timestamp']?.toString());
    final relativeTime = formatRelativeDate(
      widget.message['timestamp']?.toString(),
    );

    // Determine priority color and icon
    Color priorityColor = colorScheme.onSurface.withOpacity(0.6);
    IconData priorityIcon = Icons.low_priority;

    if (priority.toLowerCase() == 'high') {
      priorityColor = colorScheme.error;
      priorityIcon = Icons.priority_high;
    } else if (priority.toLowerCase() == 'medium') {
      priorityColor = Colors.orange;
      priorityIcon = Icons.trending_up;
    } else {
      priorityIcon = Icons.low_priority;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(
                colorScheme,
                group,
                priority,
                priorityColor,
                priorityIcon,
                relativeTime,
                timestamp,
              ),

              // Message Content Card
              _buildMessageCard(colorScheme, messageText),

              // Details Card
              _buildDetailsCard(colorScheme, expiry, timestamp),

              // Action Buttons
              _buildActionButtons(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Message Details",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          onPressed: () {
            // Show more options
            _showMoreOptions(colorScheme);
          },
        ),
      ],
    );
  }

  Widget _buildHeaderCard(
    ColorScheme colorScheme,
    String group,
    String priority,
    Color priorityColor,
    IconData priorityIcon,
    String relativeTime,
    String timestamp,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.8),
            colorScheme.secondaryContainer.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row - Group and Priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group, size: 16, color: colorScheme.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      group,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(priorityIcon, size: 14, color: priorityColor),
                    const SizedBox(width: 4),
                    Text(
                      priority,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Time Information
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: colorScheme.onPrimaryContainer.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                relativeTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(ColorScheme colorScheme, String messageText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.message, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Message",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              messageText,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    ColorScheme colorScheme,
    String expiry,
    String timestamp,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            colorScheme,
            Icons.access_time,
            "Sent Time",
            timestamp,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(colorScheme, Icons.event_busy, "Expires", expiry),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Mark as important
                _showSnackBar("Message marked as important", colorScheme);
              },
              icon: Icon(
                Icons.star_outline,
                color: colorScheme.primary,
                size: 18,
              ),
              label: Text(
                "Mark Important",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Archive message
                _showSnackBar("Message archived", colorScheme);
              },
              icon: Icon(
                Icons.archive_outlined,
                color: colorScheme.onPrimary,
                size: 18,
              ),
              label: Text(
                "Archive",
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomSheetItem(
                colorScheme,
                Icons.share,
                "Share Message",
                () {
                  Navigator.pop(context);
                  _showSnackBar("Share functionality coming soon", colorScheme);
                },
              ),
              _buildBottomSheetItem(colorScheme, Icons.copy, "Copy Text", () {
                Navigator.pop(context);
                _showSnackBar("Message copied to clipboard", colorScheme);
              }),
              _buildBottomSheetItem(
                colorScheme,
                Icons.report_outlined,
                "Report Message",
                () {
                  Navigator.pop(context);
                  _showSnackBar("Report submitted", colorScheme);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurface.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  void _showSnackBar(String message, ColorScheme colorScheme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        backgroundColor: colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
