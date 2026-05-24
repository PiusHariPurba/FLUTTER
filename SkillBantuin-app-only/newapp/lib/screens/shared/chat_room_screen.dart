import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/chat_models.dart';
import '../../models/user_role.dart';
import '../../providers/providers.dart';
import '../../widgets/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  CHAT ROOM SCREEN  —  L99 Edition
//  Features: gradient bubbles · grouped messages · swipe-to-reply · typing dots
//           · message options · emoji tabs · reaction animation · wallpaper bg
// ═══════════════════════════════════════════════════════════════════════════════

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;
  final UserRole currentRole;

  const ChatRoomScreen({
    super.key,
    required this.room,
    required this.currentRole,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer?  _pollTimer;
  Timer?  _typingTimer;

  // ── State ───────────────────────────────────────────────────────────────────
  bool _showEmoji      = false;
  bool _isAtBottom     = true;
  bool _isSending      = false;
  bool _isTyping       = false;   // animasi dots
  bool _hasText        = false;   // morph send↔mic
  int  _emojiTab       = 0;
  ChatMessage? _replyTo;          // pesan yang di-quote

  // ── Identitas ───────────────────────────────────────────────────────────────
  late int           _chatId;
  late String        _myUserId;
  late String        _clientId;
  late ChatPartyRole _myRole;

  // ── Animasi ─────────────────────────────────────────────────────────────────
  late final AnimationController _sendBtnCtrl;
  late final AnimationController _typingCtrl;

  // ── Init ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _chatId   = int.tryParse(widget.room.id) ?? 0;
    _clientId = widget.room.clientId ?? '';
    _myRole   = widget.currentRole == UserRole.client
        ? ChatPartyRole.client : ChatPartyRole.freelancer;

    // Send-button morph animation
    _sendBtnCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));

    // Typing dots
    _typingCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _scrollCtrl.addListener(_onScroll);
    _msgCtrl.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final auth = context.read<AuthProvider>();
    _myUserId  = auth.user?.id ?? '';
    final chat = context.read<ChatProvider>();

    chat.markRoomAsRead(widget.room.id);
    chat.loadMessages(_chatId, myUserId: _myUserId, clientId: _clientId)
        .then((_) => _scrollToBottom(instant: true));

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      context.read<ChatProvider>().pollNewMessages(
        _chatId,
        myUserId:   _myUserId,
        clientId:   _clientId,
        isAtBottom: _isAtBottom,
      ).then((n) {
        if (n > 0 && _isAtBottom) _scrollToBottom();
        if (n > 0 && !_isAtBottom) HapticFeedback.lightImpact();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _sendBtnCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_isAtBottom) {
      Future.delayed(const Duration(milliseconds: 280), _scrollToBottom);
    }
  }

  // ── Listeners ────────────────────────────────────────────────────────────────

  void _onScroll() {
    final atBottom = _scrollCtrl.hasClients &&
        _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 100;
    if (atBottom != _isAtBottom) {
      setState(() => _isAtBottom = atBottom);
      if (atBottom) context.read<ChatProvider>().clearNewUnseen(_chatId);
    }
  }

  void _onTextChanged() {
    final has = _msgCtrl.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
      if (has) _sendBtnCtrl.forward(); else _sendBtnCtrl.reverse();
    }
    // Simulate typing indicator feedback
    if (has) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isTyping = false);
      });
    }
  }

  // ── Scroll ───────────────────────────────────────────────────────────────────

  void _scrollToBottom({bool instant = false}) {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: instant ? const Duration(milliseconds: 1)
                        : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Send ─────────────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final reply = _replyTo;
    _msgCtrl.clear();
    setState(() { _showEmoji = false; _isSending = true; _replyTo = null; });
    HapticFeedback.lightImpact();

    final body = reply != null
        ? '[reply:${reply.id}] $text'
        : text;

    await context.read<ChatProvider>().sendMessage(
      chatId: _chatId, myUserId: _myUserId, clientId: _clientId,
      mySenderRole: _myRole, body: body, type: 'text',
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _pickMedia(String type) async {
    Navigator.pop(context);
    setState(() => _isSending = true);

    FilePickerResult? result;
    result = await FilePicker.platform.pickFiles(
      type: type == 'image' ? FileType.image : FileType.any,
    );
    if (result == null || result.files.single.path == null) {
      setState(() => _isSending = false);
      return;
    }

    await context.read<ChatProvider>().sendMessage(
      chatId: _chatId, myUserId: _myUserId, clientId: _clientId,
      mySenderRole: _myRole,
      localFilePath: result.files.single.path,
      type: type,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  // ── Long-press options ────────────────────────────────────────────────────────

  void _showMessageOptions(ChatMessage msg, bool isMine) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageOptionsSheet(
        message:  msg,
        isMine:   isMine,
        myUserId: _myUserId,
        onReact: (emoji) {
          Navigator.pop(context);
          context.read<ChatProvider>().toggleReaction(
            _chatId, msg.id, emoji, _myUserId);
        },
        onReply: () {
          Navigator.pop(context);
          setState(() => _replyTo = msg);
          FocusScope.of(context).requestFocus(FocusNode());
          Future.delayed(const Duration(milliseconds: 100), () {
            FocusScope.of(context).unfocus();
          });
        },
        onCopy: () {
          Navigator.pop(context);
          Clipboard.setData(ClipboardData(text: msg.content));
          ScaffoldMessenger.of(context).showSnackBar(
            _snack('Pesan disalin'),
          );
        },
      ),
    );
  }

  // ── Attachment picker ────────────────────────────────────────────────────────

  void _showAttachPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttachSheet(onPick: _pickMedia),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chat     = context.watch<ChatProvider>();
    final messages = chat.getMessages(_chatId);
    final hasNew   = chat.hasNewUnseen(_chatId);

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E3),
      extendBodyBehindAppBar: false,
      appBar: _AppBar(room: widget.room),
      body: Stack(
        children: [
          // ── Wallpaper background ──────────────────────────────
          const Positioned.fill(child: _ChatWallpaper()),

          Column(
            children: [
              // ── Task bar ───────────────────────────────────────
              _TaskStatusBar(room: widget.room),

              // ── Message list ───────────────────────────────────
              Expanded(
                child: _MessageList(
                  messages:    messages,
                  myRole:      _myRole,
                  myUserId:    _myUserId,
                  scrollCtrl:  _scrollCtrl,
                  isLoading:   chat.isLoading,
                  onLongPress: _showMessageOptions,
                  onSwipeReply: (msg) => setState(() => _replyTo = msg),
                  onImageTap:  (url) => _openFullImage(url),
                ),
              ),

              // ── Scroll-to-bottom FAB ───────────────────────────
              if (!_isAtBottom)
                _ScrollFab(
                  hasNew: hasNew,
                  onTap: () {
                    _scrollToBottom();
                    context.read<ChatProvider>().clearNewUnseen(_chatId);
                  },
                ),

              // ── Typing indicator ───────────────────────────────
              if (_isTyping)
                _TypingBubble(ctrl: _typingCtrl),

              // ── Reply preview bar ──────────────────────────────
              if (_replyTo != null)
                _ReplyPreviewBar(
                  message:  _replyTo!,
                  onCancel: () => setState(() => _replyTo = null),
                ),

              // ── Emoji keyboard ─────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                child: _showEmoji
                    ? _EmojiPanel(
                        activeTab: _emojiTab,
                        onTabChange: (i) => setState(() => _emojiTab = i),
                        onEmoji: (e) {
                          _msgCtrl.text += e;
                          _msgCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: _msgCtrl.text.length));
                        },
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Input bar ──────────────────────────────────────
              _InputBar(
                ctrl:          _msgCtrl,
                hasText:       _hasText,
                isSending:     _isSending,
                showingEmoji:  _showEmoji,
                sendBtnCtrl:   _sendBtnCtrl,
                onToggleEmoji: () => setState(() {
                  _showEmoji = !_showEmoji;
                  if (_showEmoji) FocusScope.of(context).unfocus();
                }),
                onAttach:  _showAttachPicker,
                onSend:    _sendText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openFullImage(String url) => Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => _FullImageScreen(url: url),
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, a, __, c) =>
          FadeTransition(opacity: a, child: c),
    ),
  );

  SnackBar _snack(String msg) => SnackBar(
    content: Text(msg),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    backgroundColor: const Color(0xFF1A6B55),
    duration: const Duration(seconds: 2),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  APP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatRoom room;
  const _AppBar({required this.room});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3D2A), Color(0xFF1A6B55)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // Back
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              // Avatar
              _AppBarAvatar(
                name:   room.counterpartName,
                url:    room.counterpartAvatar,
                online: room.counterpartOnline,
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      room.counterpartName,
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: Colors.white),
                    ),
                    Text(
                      room.counterpartOnline ? 'Online' : room.counterpartRoleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: room.counterpartOnline
                            ? const Color(0xFF6EE7B7)
                            : Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ChatInfoSheet(room: room),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final bool online;
  const _AppBarAvatar({required this.name, this.url, required this.online});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: online ? const Color(0xFF6EE7B7) : Colors.white30,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: (url != null && url!.isNotEmpty)
                ? Image.network(url!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials())
                : _initials(),
          ),
        ),
        if (online)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1A6B55), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials() => Container(
    color: const Color(0xFF2D9470),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WALLPAPER BACKGROUND
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatWallpaper extends StatelessWidget {
  const _ChatWallpaper();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WallpaperPainter(),
      child: Container(),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A6B55).withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    const r = 3.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Alternating dot pattern
        final offset = (y / spacing).floor().isEven ? 0.0 : spacing / 2;
        canvas.drawCircle(Offset(x + offset, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TASK STATUS BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _TaskStatusBar extends StatelessWidget {
  final ChatRoom room;
  const _TaskStatusBar({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      color: const Color(0xFFE8F4F0),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF1A6B55), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              room.taskTitle,
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A6B55)),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B55).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              room.counterpartRoleLabel,
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1A6B55)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MESSAGE LIST
// ═══════════════════════════════════════════════════════════════════════════════

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ChatPartyRole myRole;
  final String myUserId;
  final ScrollController scrollCtrl;
  final bool isLoading;
  final void Function(ChatMessage, bool) onLongPress;
  final void Function(ChatMessage) onSwipeReply;
  final void Function(String) onImageTap;

  const _MessageList({
    required this.messages,
    required this.myRole,
    required this.myUserId,
    required this.scrollCtrl,
    required this.isLoading,
    required this.onLongPress,
    required this.onSwipeReply,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const _ChatSkeleton();
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg    = messages[i];
        final isMine = msg.sender == myRole;

        // Grouping: same sender, within 2 min of next
        final isFirst = i == 0 || messages[i - 1].sender != msg.sender;
        final isLast  = i == messages.length - 1 ||
            messages[i + 1].sender != msg.sender;

        // Date divider
        final showDate = i == 0 || !_sameDay(messages[i - 1].createdAt, msg.createdAt);

        return Column(
          key: ValueKey(msg.id),
          children: [
            if (showDate) _DateChip(date: msg.createdAt),
            _SwipeableMessage(
              message:  msg,
              isMine:   isMine,
              isFirst:  isFirst,
              isLast:   isLast,
              myUserId: myUserId,
              onLongPress: () => onLongPress(msg, isMine),
              onSwipeReply: () => onSwipeReply(msg),
              onImageTap: () {
                if (msg.attachment != null) onImageTap(msg.attachment!);
              },
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SKELETON LOADING
// ═══════════════════════════════════════════════════════════════════════════════

class _ChatSkeleton extends StatefulWidget {
  const _ChatSkeleton();
  @override
  State<_ChatSkeleton> createState() => _ChatSkeletonState();
}

class _ChatSkeletonState extends State<_ChatSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skel(false, 200),
        _skel(true, 160),
        _skel(false, 240),
        _skel(true, 120),
        _skel(false, 180),
        _skel(true, 200),
      ],
    );
  }

  Widget _skel(bool right, double w) {
    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Container(
            width: w,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFFDDD9D4),
                  Color(0xFFEEEBE7),
                  Color(0xFFDDD9D4),
                ],
                stops: [
                  (_anim.value - 0.5).clamp(0.0, 1.0),
                  _anim.value.clamp(0.0, 1.0),
                  (_anim.value + 0.5).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DATE CHIP
// ═══════════════════════════════════════════════════════════════════════════════

class _DateChip extends StatelessWidget {
  final DateTime? date;
  const _DateChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    String label;
    if (date == null) {
      label = 'Hari ini';
    } else {
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(date!.year, date!.month, date!.day)).inDays;
      label = diff == 0
          ? 'Hari ini'
          : diff == 1
              ? 'Kemarin'
              : '${date!.day}/${date!.month}/${date!.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SWIPEABLE MESSAGE WRAPPER
// ═══════════════════════════════════════════════════════════════════════════════

class _SwipeableMessage extends StatefulWidget {
  final ChatMessage message;
  final bool isMine, isFirst, isLast;
  final String myUserId;
  final VoidCallback onLongPress, onSwipeReply, onImageTap;

  const _SwipeableMessage({
    required this.message,
    required this.isMine,
    required this.isFirst,
    required this.isLast,
    required this.myUserId,
    required this.onLongPress,
    required this.onSwipeReply,
    required this.onImageTap,
  });

  @override
  State<_SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<_SwipeableMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeCtrl;
  double _dragX = 0;
  bool   _triggered = false;

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
  }

  @override
  void dispose() { _swipeCtrl.dispose(); super.dispose(); }

  void _onHorizontalDrag(DragUpdateDetails d) {
    final dx = (_dragX + d.delta.dx).clamp(0.0, 70.0);
    setState(() => _dragX = dx);
    if (dx >= 60 && !_triggered) {
      _triggered = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    if (_triggered) widget.onSwipeReply();
    _triggered = false;
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDrag,
      onHorizontalDragEnd:    _onDragEnd,
      onLongPress:            widget.onLongPress,
      child: Stack(
        children: [
          // Reply arrow indicator
          if (_dragX > 10)
            Positioned(
              left: widget.isMine ? null : math.max(0, _dragX - 42),
              right: widget.isMine ? math.max(0, _dragX - 42) : null,
              top: 0, bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  opacity: (_dragX / 60).clamp(0.0, 1.0),
                  duration: Duration.zero,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A6B55).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.reply_rounded,
                        color: Color(0xFF1A6B55), size: 18),
                  ),
                ),
              ),
            ),

          // Message bubble (slides horizontally)
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: _MessageBubble(
              message:  widget.message,
              isMine:   widget.isMine,
              isFirst:  widget.isFirst,
              isLast:   widget.isLast,
              myUserId: widget.myUserId,
              onImageTap: widget.onImageTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ═══════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine, isFirst, isLast;
  final String myUserId;
  final VoidCallback onImageTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isFirst,
    required this.isLast,
    required this.myUserId,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = message.type == ChatMessageType.image;
    final isFile  = message.type == ChatMessageType.file;
    final hasReactions = message.reactions.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? (hasReactions ? 2 : 6) : 1,
        left:  isMine ? 52 : 4,
        right: isMine ? 4 : 52,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          _buildBubble(context, isImage, isFile),

          // Reactions
          if (hasReactions)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: _ReactionsRow(
                reactions: message.reactions,
                myUserId:  myUserId,
              ),
            ),

          // Timestamp + status
          if (isLast)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.timeLabel,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8C8580),
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 3),
                    _StatusIcon(
                      status:      message.status,
                      localStatus: message.localStatus,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isImage, bool isFile) {
    // Border radius with grouped message support
    final r = BorderRadius.only(
      topLeft:     Radius.circular(isMine ? 18 : (isFirst ? 18 : 4)),
      topRight:    Radius.circular(isMine ? (isFirst ? 18 : 4) : 18),
      bottomLeft:  Radius.circular(isMine ? 18 : (isLast ? 4 : 4)),
      bottomRight: Radius.circular(isMine ? (isLast ? 4 : 4) : 18),
    );

    Widget content;
    if (isImage) {
      content = _ImageBubble(
        attachment: message.attachment,
        onTap:      onImageTap,
        isMine:     isMine,
        borderRadius: r,
      );
    } else if (isFile) {
      content = _FileBubble(
        attachment: message.attachment,
        isMine:     isMine,
      );
    } else {
      content = _TextBubble(
        content: message.content,
        isMine:  isMine,
        failed:  message.localStatus == LocalMessageStatus.failed,
      );
    }

    if (isMine) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: message.localStatus == LocalMessageStatus.failed
              ? const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A6B55), Color(0xFF2D9470)]),
          borderRadius: r,
          boxShadow: const [
            BoxShadow(
              color: Color(0x221A6B55),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: r, child: content),
      );
    } else {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: r,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: r, child: content),
      );
    }
  }
}

// ── Text Bubble Content ────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final String content;
  final bool isMine, failed;
  const _TextBubble({required this.content, required this.isMine, required this.failed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: isMine ? Colors.white : const Color(0xFF1A1918),
          height: 1.45,
        ),
      ),
    );
  }
}

// ── Image Bubble Content ──────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final String? attachment;
  final bool isMine;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _ImageBubble({
    required this.attachment,
    required this.isMine,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (attachment == null) {
      img = _placeholder();
    } else if (attachment!.startsWith('http')) {
      img = Image.network(
        attachment!,
        width: 230, height: 200, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: 230, height: 200,
                color: const Color(0xFFE8F4F0),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A6B55), strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } else {
      img = Image.file(
        File(attachment!),
        width: 230, height: 200, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: attachment ?? 'img',
        child: img,
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 230, height: 160,
    color: const Color(0xFF1A3025),
    child: const Icon(Icons.image_rounded, color: Colors.white24, size: 48),
  );
}

// ── File Bubble Content ───────────────────────────────────────────────────────

class _FileBubble extends StatelessWidget {
  final String? attachment;
  final bool isMine;
  const _FileBubble({required this.attachment, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final name = attachment?.split('/').last ?? 'File';
    final ext  = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isMine
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFE8F4F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file_rounded,
                  color: isMine ? Colors.white : const Color(0xFF1A6B55),
                  size: 18),
                Text(ext,
                  style: TextStyle(
                    fontSize: 7, fontWeight: FontWeight.w800,
                    color: isMine ? Colors.white : const Color(0xFF1A6B55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isMine ? Colors.white : const Color(0xFF1A1918)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ketuk untuk unduh',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF9C9893)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.download_rounded,
            color: isMine ? Colors.white70 : const Color(0xFF1A6B55),
            size: 20),
        ],
      ),
    );
  }
}

// ── Status Icon ───────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final ChatStatus status;
  final LocalMessageStatus localStatus;
  const _StatusIcon({required this.status, required this.localStatus});

  @override
  Widget build(BuildContext context) {
    if (localStatus == LocalMessageStatus.pending) {
      return const SizedBox(
        width: 13, height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 1.5, color: Color(0xFF9C9893)),
      );
    }
    if (localStatus == LocalMessageStatus.failed) {
      return const Icon(Icons.error_outline_rounded,
          size: 14, color: Color(0xFFDC2626));
    }
    return Icon(
      status == ChatStatus.read
          ? Icons.done_all_rounded
          : Icons.done_rounded,
      size: 14,
      color: status == ChatStatus.read
          ? const Color(0xFF60E0FF)
          : const Color(0xFFB0C4C0),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REACTIONS ROW
// ═══════════════════════════════════════════════════════════════════════════════

class _ReactionsRow extends StatelessWidget {
  final List<MessageReaction> reactions;
  final String myUserId;
  const _ReactionsRow({required this.reactions, required this.myUserId});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: reactions.map((r) {
        final mine = r.userIds.contains(myUserId);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: mine
                  ? const Color(0xFFDCF7ED)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: mine
                    ? const Color(0xFF1A6B55).withOpacity(0.5)
                    : const Color(0xFFE5E2DE),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 14)),
                if (r.userIds.length > 1) ...[
                  const SizedBox(width: 3),
                  Text(
                    '${r.userIds.length}',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: mine
                          ? const Color(0xFF1A6B55)
                          : const Color(0xFF5C5855)),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TYPING INDICATOR
// ═══════════════════════════════════════════════════════════════════════════════

class _TypingBubble extends StatelessWidget {
  final AnimationController ctrl;
  const _TypingBubble({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 60, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(18),
              topRight:    Radius.circular(18),
              bottomLeft:  Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _Dot(ctrl: ctrl, index: i)),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController ctrl;
  final int index;
  const _Dot({required this.ctrl, required this.index});

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.2;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value - delay) % 1.0 + 1.0) % 1.0;
        final y = -math.sin(t * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, y),
          child: Container(
            width: 7, height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFFB0B0B0),
                const Color(0xFF1A6B55),
                math.sin(t * math.pi).clamp(0.0, 1.0),
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REPLY PREVIEW BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _ReplyPreviewBar extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCancel;
  const _ReplyPreviewBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      color: const Color(0xFFE8F4F0),
      child: Row(
        children: [
          Container(
            width: 3, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Membalas',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A6B55)),
                ),
                Text(
                  message.content.isNotEmpty
                      ? message.content
                      : '📎 Lampiran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12, color: Color(0xFF5C5855)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18,
                color: Color(0xFF5C5855)),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SCROLL FAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ScrollFab extends StatelessWidget {
  final bool hasNew;
  final VoidCallback onTap;
  const _ScrollFab({required this.hasNew, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 4),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: hasNew ? 12 : 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1A6B55).withOpacity(0.3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasNew) ...[
                  const Text(
                    'Pesan baru',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFF1A6B55)),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF1A6B55), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EMOJI PANEL  (tabbed categories)
// ═══════════════════════════════════════════════════════════════════════════════

class _EmojiPanel extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChange;
  final ValueChanged<String> onEmoji;

  const _EmojiPanel({
    required this.activeTab,
    required this.onTabChange,
    required this.onEmoji,
  });

  static const _tabs = ['😊', '👋', '❤️', '🌿'];
  static const _categories = [
    // Ekspresi
    ['😀','😂','🥰','😍','😊','🤣','😢','😡','🤔','😮','😴','🥳',
     '😎','🤩','😇','🥺','😤','😷','🤒','🤓','😜','😝','🫠','🤭'],
    // Tangan & gestur
    ['👍','👎','👏','🙏','🤝','✌️','💪','🫶','🤞','👋','🤙','✋',
     '🖐️','☝️','👌','🤌','🤏','🖖','🤘','🫵','👈','👉','👆','👇'],
    // Hati & simbol
    ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','💔','❤️‍🔥','💯','✅',
     '❌','⭐','🌟','💫','✨','🔥','🎉','🎊','🏆','🥇','💰','🚀'],
    // Alam & lainnya
    ['🌺','🌸','🌼','🍀','🌿','🌊','🌈','☀️','🌙','⚡','🎵','📸',
     '💻','📱','🎯','⏰','📝','💡','🔑','🎁','🍕','☕','🍰','🎂'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Tab bar
          Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEECE8))),
            ),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = i == activeTab;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChange(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: active
                                ? const Color(0xFF1A6B55)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(_tabs[i],
                          style: TextStyle(
                            fontSize: active ? 22 : 18),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _categories[activeTab].length,
              itemBuilder: (_, i) {
                final e = _categories[activeTab][i];
                return GestureDetector(
                  onTap: () => onEmoji(e),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  INPUT BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool hasText, isSending, showingEmoji;
  final AnimationController sendBtnCtrl;
  final VoidCallback onToggleEmoji, onAttach, onSend;

  const _InputBar({
    required this.ctrl,
    required this.hasText,
    required this.isSending,
    required this.showingEmoji,
    required this.sendBtnCtrl,
    required this.onToggleEmoji,
    required this.onAttach,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach button
            _CircleBtn(
              icon: Icons.add_rounded,
              onTap: onAttach,
              bg: Colors.white,
            ),
            const SizedBox(width: 6),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 130),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 15, color: Color(0xFF1A1918), height: 1.4),
                        decoration: const InputDecoration(
                          hintText: 'Pesan...',
                          hintStyle: TextStyle(
                            color: Color(0xFFBBB8B3), fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    // Emoji toggle
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 6),
                      child: GestureDetector(
                        onTap: onToggleEmoji,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            showingEmoji
                                ? Icons.keyboard_rounded
                                : Icons.emoji_emotions_outlined,
                            color: const Color(0xFF9C9893),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send / Mic button — morphs
            AnimatedBuilder(
              animation: sendBtnCtrl,
              builder: (_, __) {
                final t = sendBtnCtrl.value;
                return GestureDetector(
                  onTap: isSending ? null : (hasText ? onSend : null),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF2D9470),
                              const Color(0xFF1A6B55), t)!,
                          Color.lerp(const Color(0xFF1A6B55),
                              const Color(0xFF0F3D2A), t)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A6B55).withOpacity(0.35 + t * 0.1),
                          blurRadius: 10 + t * 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            hasText
                                ? Icons.send_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  const _CircleBtn({required this.icon, required this.onTap, required this.bg});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: bg,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5C5855), size: 22),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MESSAGE OPTIONS SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _MessageOptionsSheet extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String myUserId;
  final ValueChanged<String> onReact;
  final VoidCallback onReply, onCopy;

  const _MessageOptionsSheet({
    required this.message,
    required this.isMine,
    required this.myUserId,
    required this.onReact,
    required this.onReply,
    required this.onCopy,
  });

  static const _quickEmoji = ['👍','❤️','😂','😮','😢','😡','🎉','🙏'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _quickEmoji.map((e) {
                final active = message.reactions
                    .any((r) => r.emoji == e && r.userIds.contains(myUserId));
                return GestureDetector(
                  onTap: () => onReact(e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFE8F4F0)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(
                              color: const Color(0xFF1A6B55).withOpacity(0.4))
                          : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _OptionTile(
                  icon: Icons.reply_rounded,
                  label: 'Balas',
                  onTap: onReply,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _OptionTile(
                  icon: Icons.copy_rounded,
                  label: 'Salin',
                  onTap: onCopy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1A6B55), size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1918)),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ATTACHMENT SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _AttachSheet extends StatelessWidget {
  final void Function(String type) onPick;
  const _AttachSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD9D4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachOption(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                color: const Color(0xFF1A6B55),
                bg:    const Color(0xFFE8F4F0),
                onTap: () => onPick('image'),
              ),
              _AttachOption(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                color: const Color(0xFF0369A1),
                bg:    const Color(0xFFE0F2FE),
                onTap: () => onPick('image'),
              ),
              _AttachOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'Dokumen',
                color: const Color(0xFF7C3AED),
                bg:    const Color(0xFFEDE9FE),
                onTap: () => onPick('file'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;
  const _AttachOption({
    required this.icon, required this.label,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FULL IMAGE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class _FullImageScreen extends StatelessWidget {
  final String url;
  const _FullImageScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Foto', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gambar disimpan'),
                backgroundColor: Color(0xFF1A6B55),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: url,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: url.startsWith('http')
                ? Image.network(url, fit: BoxFit.contain)
                : Image.file(File(url), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}


// ── Chat Info Sheet (more_vert) ────────────────────────────────────────────────

class _ChatInfoSheet extends StatelessWidget {
  final ChatRoom room;
  const _ChatInfoSheet({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: const Color(0xFFDDD9D4),
            borderRadius: BorderRadius.circular(2))),
        const Text('Info Percakapan', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1918))),
        const SizedBox(height: 16),
        // Counterpart info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFE8F4F0),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2D9470)),
              child: Center(child: Text(
                room.counterpartName.isNotEmpty ? room.counterpartName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(room.counterpartName, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1918))),
              Text(room.counterpartRoleLabel, style: const TextStyle(
                fontSize: 12, color: Color(0xFF5C5855))),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        // Task info
        if (room.taskTitle.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF7F6F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEECE8))),
            child: Row(children: [
              const Icon(Icons.work_outline_rounded, color: Color(0xFF1A6B55), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(room.taskTitle, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1918)),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: const Color(0xFF1A6B55),
              borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Tutup', style: TextStyle(
              fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)))),
        ),
      ]),
    );
  }
}
