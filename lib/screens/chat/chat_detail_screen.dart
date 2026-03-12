import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/chat/chat_service.dart';
import '../../core/supabase/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/language/translations.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  late final String? _propertyId;
  late final String _receiverId;

  Message? _replyToMessage;
  Message? _editingMessage;
  List<Message> _allMessages = [];
  late final Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _propertyId = widget.chat['propertyId']?.toString();
    _receiverId = widget.chat['receiverId']?.toString() ?? '';
    _messagesStream = ChatService.getMessagesStream(_receiverId);
    _updatePresence(true);
    // Mark messages as read on entry
    _markRead();
  }

  Future<void> _markRead() async {
    await ChatService.markAsRead(_receiverId);
  }

  void _updatePresence(bool isOnline) {
    ChatService.updatePresence(isOnline);
  }

  @override
  void dispose() {
    _updatePresence(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && attachmentUrl == null) return;

    final replyToId = _replyToMessage?.id;
    final editId = _editingMessage?.id;

    setState(() {
      _messageController.clear();
      _replyToMessage = null;
      _editingMessage = null;
    });

    try {
      if (editId != null) {
        await ChatService.editMessage(editId, content);
      } else {
        await ChatService.sendMessage(
          propertyId: _propertyId,
          receiverId: _receiverId,
          content: content,
          replyToId: replyToId,
          attachmentUrl: attachmentUrl,
          attachmentType: attachmentType,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onReply(Message msg) {
    setState(() {
      _replyToMessage = msg;
      _editingMessage = null;
    });
  }

  void _onEdit(Message msg) {
    setState(() {
      _editingMessage = msg;
      _replyToMessage = null;
      _messageController.text = msg.content;
    });
  }

  void _onDelete(Message msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ChatService.deleteMessage(msg.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu() {
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
                _confirmDeleteConversation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'All messages will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ChatService.deleteConversation(
                _propertyId ?? '',
                _receiverId,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // With reverse: true, 0 is the bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded),
                title: const Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File attachments coming soon!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);

    if (image != null) {
      final bytes = await image.readAsBytes();
      _uploadAndSend(image.name, bytes, 'image');
    }
  }

  Future<void> _uploadAndSend(String name, Uint8List bytes, String type) async {
    // Show a temporary loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading attachment...'),
        duration: Duration(seconds: 2),
      ),
    );

    final url = await ChatService.uploadFile(
      path: '', // Not used in refined uploadFile
      fileName: name,
      bytes: bytes,
    );

    if (url != null) {
      _sendMessage(attachmentUrl: url, attachmentType: type);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    }
  }

  Future<void> _makeCall() async {
    // In a real app, we'd get the phone number from the chat user's profile
    // For now, we'll use a placeholder or look it up from mock data if possible
    final String phoneNumber = widget.chat['phone'] ?? '+251911223344';
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOnline = widget.chat['isOnline'] as bool? ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child:
                              (widget.chat['avatar'] as String?)?.isEmpty ??
                                  true
                              ? Container(
                                  color: theme.primaryColor,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: widget.chat['avatar'],
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: theme.primaryColor,
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 22,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<Map<String, dynamic>>(
                      stream: ChatService.getUserPresence(_receiverId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Offline', style: TextStyle(fontSize: 12)),
                            ],
                          );
                        }
                        final presence = snapshot.data ?? {'is_online': false};
                        final online = presence['is_online'] as bool? ?? false;
                        final lastSeenStr = presence['last_seen'] as String?;
                        final fullName = presence['full_name'] as String? ?? '';
                        final isAdmin =
                            fullName == 'Admin' ||
                            presence['id'] ==
                                'f04523c9-9430-4e3a-967a-569038234fd7';

                        String name = fullName.isNotEmpty
                            ? fullName
                            : (widget.chat['name'] ?? 'User');
                        if (isAdmin) name = 'Mana Kira';

                        String sub = online ? 'Online' : 'Offline';
                        if (!online && lastSeenStr != null) {
                          final lastSeen = DateTime.parse(lastSeenStr);
                          sub =
                              'Last seen ${TimeOfDay.fromDateTime(lastSeen).format(context)}';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textTheme.displayLarge?.color,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: AppColors.verified,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              sub,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: online
                                    ? AppColors.online
                                    : AppColors.textLight,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: _makeCall,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.call_rounded,
                        size: 20,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showMoreMenu,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final messages = snapshot.data ?? [];
                  _allMessages = messages;

                  // Optimized scroll and read-marking
                  if (messages.length != _lastMessageCount) {
                    _lastMessageCount = messages.length;
                    _scrollToBottom();

                    // Mark unread messages from other user as read
                    final hasUnread = messages.any(
                      (m) => m.senderId == _receiverId && !m.isRead,
                    );
                    if (hasUnread) {
                      ChatService.markAsRead(_receiverId);
                    }
                  }

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet',
                        style: GoogleFonts.inter(color: AppColors.textLight),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Latest messages (index 0) at the bottom
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == AuthService.currentUser?.id;
                      return _messageBubble(msg, isMe, theme);
                    },
                  );
                },
              ),
            ),

            // Edit/Reply Preview
            if (_replyToMessage != null || _editingMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerTheme.color ?? AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _replyToMessage != null
                          ? Icons.reply_rounded
                          : Icons.edit_rounded,
                      size: 18,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _replyToMessage != null
                                ? 'Replying to'
                                : 'Editing message',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: theme.primaryColor,
                            ),
                          ),
                          Text(
                            (_replyToMessage ?? _editingMessage)!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_editingMessage != null) _messageController.clear();
                        _replyToMessage = null;
                        _editingMessage = null;
                      }),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        size: 20,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) async {
                          await _sendMessage();
                        },
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'type_message'.tr(context),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          isDense: true,
                          filled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await _sendMessage();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: isDark
                            ? theme.scaffoldBackgroundColor
                            : Colors.white,
                      ),
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

  Widget _messageBubble(Message msg, bool isMe, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final sentColor = theme.primaryColor;
    final receivedColor = theme.inputDecorationTheme.fillColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _showMessageActions(msg, isMe),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? sentColor : receivedColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg.replyToId != null)
                    _replyPreviewInBubble(msg.replyToId!, isMe, theme),
                  if (msg.attachmentUrl != null)
                    _mediaPreview(msg, isMe, theme),
                  if (msg.content.isNotEmpty)
                    Text(
                      msg.content,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isMe
                            ? (isDark
                                  ? theme.scaffoldBackgroundColor
                                  : Colors.white)
                            : theme.textTheme.displayLarge?.color,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '(edited)',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isMe
                                  ? (isDark
                                            ? theme.scaffoldBackgroundColor
                                            : Colors.white)
                                        .withValues(alpha: 0.5)
                                  : AppColors.textLight.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      Text(
                        TimeOfDay.fromDateTime(msg.createdAt).format(context),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMe
                              ? (isDark
                                        ? theme.scaffoldBackgroundColor
                                        : Colors.white)
                                    .withValues(alpha: 0.6)
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaPreview(Message msg, bool isMe, ThemeData theme) {
    if (msg.attachmentType == 'image') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: msg.attachmentUrl!.isEmpty
              ? _buildMediaError(theme)
              : CachedNetworkImage(
                  imageUrl: msg.attachmentUrl!,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.black.withValues(alpha: 0.05),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildMediaError(theme),
                  fit: BoxFit.cover,
                ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(msg.attachmentUrl!)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                color: isMe ? Colors.white70 : theme.primaryColor,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Media File',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isMe
                        ? Colors.white
                        : theme.textTheme.displayLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMediaError(ThemeData theme) {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.05),
      child: const Icon(Icons.broken_image_rounded, color: AppColors.textLight),
    );
  }

  Widget _replyPreviewInBubble(String replyToId, bool isMe, ThemeData theme) {
    final repliedMsg = _allMessages.firstWhere(
      (m) => m.id == replyToId,
      orElse: () => Message(
        id: '',
        senderId: '',
        receiverId: '',
        propertyId: '',
        content: 'Replying to previous message...',
        isRead: true,
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white70 : theme.primaryColor,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            repliedMsg.senderId == AuthService.currentUser?.id
                ? 'You'
                : 'Reply',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white70 : theme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            repliedMsg.attachmentUrl != null && repliedMsg.content.isEmpty
                ? '📷 Photo'
                : repliedMsg.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isMe ? Colors.white70 : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(Message msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _onReply(msg);
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _onEdit(msg);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _onDelete(msg);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
