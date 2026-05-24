import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  Future<void> _markAllRead() async {
    await context.read<NotificationProvider>().markAllAsRead();
  }

  Future<void> _markOneRead(dynamic id) async {
    await context.read<NotificationProvider>().markAsRead(
      int.tryParse(id.toString()) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FPal.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: FPal.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: FPal.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Baca Semua',
              style: TextStyle(
                color: FPal.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: FPal.primary),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 72, color: FPal.inkMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FPal.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Notifikasi akan muncul di sini',
                    style: TextStyle(fontSize: 13, color: FPal.inkMuted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: FPal.primary,
            onRefresh: provider.fetchNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                return _NotifCard(
                  notif: notif,
                  onTap: () => _markOneRead(notif.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Notification Card ──────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final NotificationItem notif;
  final VoidCallback onTap;

  const _NotifCard({required this.notif, required this.onTap});

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_message':         return Icons.chat_bubble_outline_rounded;
      case 'offer_received':      return Icons.work_outline_rounded;
      case 'offer_accepted':      return Icons.check_circle_outline_rounded;
      case 'payment_verified':    return Icons.payments_outlined;
      case 'task_completed':      return Icons.task_alt_rounded;
      default:                    return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'offer_accepted':
      case 'task_completed':   return const Color(0xFF16A34A);
      case 'payment_verified': return const Color(0xFF7C3AED);
      case 'offer_received':   return FPal.primary;
      default:                 return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notif.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? const Color(0xFFE8E5E0)
                : color.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(notif.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: FPal.ink,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: FPal.inkMuted,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: FPal.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)     return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}