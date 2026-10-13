import 'package:flutter/material.dart' hide Text;
import '../services/api_service.dart';
import '../widgets/localized_text.dart';

class TechnicianNotificationItem {
  final String title;
  final String message;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final bool unread;
  final int? noticeId;

  const TechnicianNotificationItem({
    required this.title,
    required this.message,
    required this.createdAt,
    required this.icon,
    required this.color,
    this.unread = true,
    this.noticeId,
  });

  TechnicianNotificationItem copyWith({bool? unread}) {
    return TechnicianNotificationItem(
      title: title,
      message: message,
      createdAt: createdAt,
      icon: icon,
      color: color,
      unread: unread ?? this.unread,
      noticeId: noticeId,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final List<TechnicianNotificationItem> notifications;
  final int? technicianId;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    this.technicianId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final List<TechnicianNotificationItem> _notifications =
      List.of(widget.notifications);

  Future<void> _markNoticeRead(int index, TechnicianNotificationItem item) async {
    final technicianId = widget.technicianId;
    final noticeId = item.noticeId;
    if (technicianId == null || noticeId == null || !item.unread) return;

    final result = await ApiService.markTechnicianNoticeRead(
      technicianId: technicianId,
      noticeId: noticeId,
    );
    if (!mounted) return;
    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (result['message'] ?? 'Unable to mark notice as read').toString(),
          ),
        ),
      );
      return;
    }

    setState(() => _notifications[index] = item.copyWith(unread: false));
  }

  @override
  Widget build(BuildContext context) {
    final items = _notifications.isEmpty
        ? [
            TechnicianNotificationItem(
              title: 'No recent activity',
              message:
                  'Your technician activity will appear here once you have new updates.',
              createdAt: DateTime.now(),
              icon: Icons.notifications_none_rounded,
              color: Colors.blue,
              unread: false,
            ),
          ]
        : _notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final formattedTime = _formatTime(item.createdAt);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: item.noticeId == null
                ? null
                : () => _markNoticeRead(index, item),
            child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.unread
                    ? item.color.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (item.unread)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }

    return 'Just now';
  }
}
