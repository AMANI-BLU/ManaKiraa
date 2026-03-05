import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/utils/time_utils.dart';
import '../../core/supabase/supabase_service.dart';
import '../chat/chat_detail_screen.dart';
import '../property/property_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the user navigates back to this screen
    final route = ModalRoute.of(this.context);
    if (route != null && route.isCurrent) {
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final notifs = await NotificationService.getPersistedNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int index) async {
    setState(() {
      _notifications[index] = {..._notifications[index], 'isRead': true};
    });
    await NotificationService.instance.markAsRead(index);
  }

  Future<void> _onNotifTap(int index, Map<String, dynamic> notif) async {
    await _markAsRead(index);
    final type = notif['type'] as String? ?? '';

    if (!mounted) return;

    if (type == 'new_listing') {
      final propertyId = notif['propertyId']?.toString();
      if (propertyId != null) {
        // Fetch the property from Supabase and navigate
        try {
          final properties = await SupabaseService.fetchProperties();
          final property = properties.firstWhere(
            (p) => p.id == propertyId,
            orElse: () => properties.first,
          );
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: property),
              ),
            );
          }
        } catch (_) {}
      }
    } else if (type == 'chat' || type == 'message') {
      // 'chat' is set by in-app listener, 'message' for FCM from backend
      final senderId =
          notif['chat_id']?.toString() ?? notif['receiverId']?.toString();
      if (senderId != null) {
        final chat = {
          'name': notif['title'] ?? 'Chat',
          'avatar': 'https://ui-avatars.com/api/?name=User&background=random',
          'isOnline': false,
          'propertyId':
              notif['propertyId'], // null is fine for consolidated chats
          'receiverId': senderId,
        };
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatDetailScreen(chat: chat)),
          );
        }
      }
    }
  }

  Future<void> _clearAll() async {
    await NotificationService.clearNotifications();
    setState(() {
      _notifications = [];
    });
  }

  Future<void> _dismiss(int index) async {
    // Remove from in-memory list
    setState(() {
      _notifications.removeAt(index);
    });
    // Persist the removal so it does not reappear on reload
    await NotificationService.removeNotificationAt(index);
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'new':
        return Icons.home_rounded;
      case 'price':
        return Icons.trending_down_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'new':
        return AppColors.notifNew;
      case 'price':
        return AppColors.notifPrice;
      case 'message':
        return AppColors.notifMessage;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'notifications'.tr(context),
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  if (_notifications.any((n) => !(n['isRead'] as bool)))
                    GestureDetector(
                      onTap: _clearAll,
                      child: Text(
                        'clear_all'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: AppColors.textLight.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_notifications'.tr(context),
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _notifications.length,
                      separatorBuilder: (a1, a2) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isRead = notif['isRead'] as bool;
                        final type = notif['type'] as String;

                        return Dismissible(
                          key: ValueKey('notif_${notif['title']}_$index'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _dismiss(index),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => _onNotifTap(index, notif),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? theme.colorScheme.surface
                                    : _getIconColor(
                                        type,
                                      ).withValues(alpha: isDark ? 0.15 : 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: isRead
                                    ? null
                                    : Border.all(
                                        color: _getIconColor(type).withValues(
                                          alpha: isDark ? 0.3 : 0.15,
                                        ),
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.1 : 0.03,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _getIconColor(
                                        type,
                                      ).withValues(alpha: isDark ? 0.2 : 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      _getIcon(type),
                                      size: 22,
                                      color: _getIconColor(type),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif['title'],
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: isRead
                                                ? FontWeight.w600
                                                : FontWeight.w700,
                                            color: theme
                                                .textTheme
                                                .displayLarge
                                                ?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          notif['message'],
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        TimeUtils.timeAgo(
                                          DateTime.parse(notif['timestamp']),
                                        ),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getIconColor(type),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
