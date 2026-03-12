import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';
import '../../core/chat/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _searchQuery = '';
  late final Stream<List<Map<String, dynamic>>> _conversationsStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = ChatService.getConversationsStream();
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'messages'.tr(context),
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
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
                      Icons.edit_note_rounded,
                      size: 22,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Chat List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _conversationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chats = snapshot.data ?? [];
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final filteredChats = chats.where((chat) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    final name = (chat['name'] as String).toLowerCase();
                    final message = (chat['message'] as String).toLowerCase();
                    return name.contains(query) || message.contains(query);
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: AppColors.textLight.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No conversations yet'
                                : 'No results found',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: ChatService.refreshConversations,
                    color: theme.primaryColor,
                    backgroundColor: theme.colorScheme.surface,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredChats.length,
                      separatorBuilder: (a1, a2) => Padding(
                        padding: const EdgeInsets.only(left: 72),
                        child: Divider(
                          color:
                              theme.dividerTheme.color?.withValues(
                                alpha: 0.5,
                              ) ??
                              AppColors.divider.withValues(alpha: 0.5),
                          height: 1,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return GestureDetector(
                          onTap: () async {
                            // Optimistic clear for immediate feel
                            if (chat['unread'] > 0) {
                              ChatService.markAsRead(chat['receiverId']);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(chat: chat),
                              ),
                            );
                          },
                          onLongPress: () => _showConversationMenu(chat),
                          behavior: HitTestBehavior.opaque,
                          child: _chatTile(chat, theme),
                        );
                      },
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

  void _showConversationMenu(Map<String, dynamic> chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Delete Conversation',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation(Map<String, dynamic> chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete all messages with ${chat['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ChatService.deleteConversation(
                chat['propertyId'],
                chat['receiverId'],
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _chatTile(Map<String, dynamic> chat, ThemeData theme) {
    final int unread = chat['unread'] as int;
    final bool isOnline = chat['isOnline'] as bool? ?? false;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.06,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (chat['avatar'] as String?)?.isEmpty ?? true
                      ? Container(
                          color: theme.primaryColor,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: chat['avatar'],
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: theme.primaryColor,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Name + Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      chat['name'],
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: unread > 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                    if (chat['isAdmin'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.verified,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  chat['message'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: unread > 0
                        ? theme.textTheme.displayLarge?.color
                        : AppColors.textLight,
                    fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time + Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat['time'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: unread > 0 ? theme.primaryColor : AppColors.textLight,
                  fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              if (unread > 0)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? theme.scaffoldBackgroundColor
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
