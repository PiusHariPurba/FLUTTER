import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/demo_config.dart';
import '../../models/chat_models.dart';
import '../../models/user_role.dart';
import '../../providers/providers.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/app_animations.dart';
import '../shared/chat_room_screen.dart';

class ClientChatListScreen extends StatefulWidget {
  const ClientChatListScreen({super.key});
  @override
  State<ClientChatListScreen> createState() => _ClientChatListScreenState();
}

class _ClientChatListScreenState extends State<ClientChatListScreen> {
  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _searchOpen   = false;
  bool _scrolled     = false;
  bool _isDemo       = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _scrollCtrl.dispose(); super.dispose();
  }

  void _onScroll() {
    final s = _scrollCtrl.position.pixels > 8;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  void _load() {
    final auth = context.read<AuthProvider>().user;
    if (auth != null) {
      context.read<ChatProvider>().loadChats(
        myUserId: auth.id, myRole: auth.role.name);
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    _load();
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _navToRoom(ChatRoom room) {
    final auth = context.read<AuthProvider>().user;
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => ChatRoomScreen(
        room: room, currentRole: UserRole.client),
      transitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (_, a, __, c) => SlideTransition(
        position: Tween(begin: const Offset(1.0, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)).animate(a),
        child: c),
    ));
  }

  // ── Open Demo Chat ─────────────────────────────────────────────────
  Future<void> _openDemoChat() async {
    setState(() => _isDemo = true);
    HapticFeedback.lightImpact();

    try {
      final auth    = context.read<AuthProvider>().user;
      final chatSvc = ChatService();
      final res = await chatSvc.findOrCreateChat(
        freelancerId: DemoConfig.demoFreelancerUserId,
      );

      if (!mounted) { setState(() => _isDemo = false); return; }

      if (res.success) {
        final chatData = res['data'] as Map<String, dynamic>? ?? {};
        final room = ChatRoom.fromApiJson(chatData,
          myUserId: auth?.id ?? '', myRole: 'client');
        _navToRoom(room);
      } else {
        _showSnack('Gagal membuka demo chat: ${res.message}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
    setState(() => _isDemo = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      backgroundColor: FPal.danger,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  @override
  Widget build(BuildContext context) {
    final chat  = context.watch<ChatProvider>();
    final query = _searchCtrl.text.toLowerCase();

    var rooms = chat.rooms;
    if (query.isNotEmpty) {
      rooms = rooms.where((r) =>
        r.counterpartName.toLowerCase().contains(query) ||
        r.lastMessage.toLowerCase().contains(query)).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (_, __) => [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              totalUnread: chat.totalUnread,
              scrolled:    _scrolled,
              searchOpen:  _searchOpen,
              searchCtrl:  _searchCtrl,
              onSearch:    () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _searchCtrl.clear();
              }),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: FPal.primary, strokeWidth: 2.5,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Demo Chat Banner ────────────────────────────────
              SliverToBoxAdapter(child: _DemoBanner(
                isLoading: _isDemo, onTap: _openDemoChat)),

              // ── Empty / Loading / List ──────────────────────────
              if (chat.isLoading && rooms.isEmpty)
                SliverFillRemaining(child: _Skeleton())
              else if (rooms.isEmpty)
                SliverFillRemaining(child: _EmptyState(query: query))
              else
                SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final room = rooms[i];
                    return _ChatTile(
                      key:     ValueKey(room.id),
                      room:    room,
                      index:   i,
                      onTap:   () => _navToRoom(room),
                      onMarkRead: () =>
                          context.read<ChatProvider>().markRoomAsRead(room.id),
                    );
                  },
                  childCount: rooms.length,
                )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Demo Banner ────────────────────────────────────────────────────────────────

class _DemoBanner extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _DemoBanner({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D2A), Color(0xFF1A6B55)]),
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: const Center(child: Text('🤖',
            style: TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Chat Demo dengan Freelancer',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 13.5)),
          const Text('Coba kirim pesan — bisa diterima akun freelancer@demo.com',
            style: TextStyle(color: Colors.white70, fontSize: 11.5)),
        ])),
        if (isLoading)
          const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        else
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
      ]),
    ),
  );
}

// ── Sliver Header ──────────────────────────────────────────────────────────────

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final int totalUnread;
  final bool scrolled, searchOpen;
  final TextEditingController searchCtrl;
  final VoidCallback onSearch;

  _HeaderDelegate({required this.totalUnread, required this.scrolled,
    required this.searchOpen, required this.searchCtrl, required this.onSearch});

  @override double get minExtent => searchOpen ? 116 : 80;
  @override double get maxExtent => searchOpen ? 116 : 80;
  @override bool shouldRebuild(_HeaderDelegate old) => true;

  @override
  Widget build(BuildContext context, double shrink, bool overlap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: scrolled ? [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))] : null),
      child: SafeArea(bottom: false, child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pesan', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1918), letterSpacing: -0.5)),
              if (totalUnread > 0)
                Text('$totalUnread belum dibaca', style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: FPal.primary)),
            ])),
            GestureDetector(
              onTap: onSearch,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: const Color(0xFFF2F1EE)),
                child: Icon(
                  searchOpen ? Icons.close_rounded : Icons.search_rounded,
                  size: 18, color: const Color(0xFF1A1918)))),
          ]),
        ),
        if (searchOpen) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F1EE),
              borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: searchCtrl, autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari percakapan...',
                hintStyle: TextStyle(color: Color(0xFFB0ADA9), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                  color: Color(0xFFB0ADA9), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10))))),
      ])),
    );
  }
}

// ── Chat Tile ──────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatRoom room;
  final int index;
  final VoidCallback onTap, onMarkRead;
  const _ChatTile({super.key, required this.room, required this.index,
    required this.onTap, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return SlideInRight(
      delay: Duration(milliseconds: index * 50),
      child: Dismissible(
        key: Key('tile_${room.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: FPal.primary,
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text('Baca', style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ])),
        confirmDismiss: (_) async { onMarkRead(); return false; },
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              // Avatar
              Stack(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: FPal.primaryLight,
                    border: Border.all(
                      color: FPal.primary.withOpacity(0.2), width: 1.5)),
                  child: Center(child: Text(
                    room.counterpartName.isNotEmpty
                        ? room.counterpartName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: FPal.primary, fontWeight: FontWeight.w800, fontSize: 20)))),
                if (room.counterpartOnline)
                  Positioned(bottom: 1, right: 1,
                    child: Container(width: 13, height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399), shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)))),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(room.counterpartName, style: TextStyle(
                    fontSize: 15,
                    fontWeight: room.unreadCount > 0 ? FontWeight.w900 : FontWeight.w700,
                    color: const Color(0xFF1A1918)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(room.lastMessageTime, style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: room.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                    color: room.unreadCount > 0 ? FPal.primary : const Color(0xFF9C9893))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: Text(
                    room.lastMessage.isEmpty ? room.taskTitle : room.lastMessage,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                      color: room.unreadCount > 0
                          ? const Color(0xFF2D2B28) : const Color(0xFF9C9893)))),
                  if (room.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(scale: v, child: child),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: FPal.primary,
                          borderRadius: BorderRadius.circular(11)),
                        child: Center(child: Text(
                          room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                          style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))))),
                  ],
                ]),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80,
        decoration: const BoxDecoration(
          color: FPal.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded,
          size: 36, color: FPal.primary)),
      const SizedBox(height: 14),
      Text(query.isNotEmpty ? 'Tidak ada hasil' : 'Belum ada percakapan',
        style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1918))),
      const SizedBox(height: 6),
      Text(query.isNotEmpty ? 'Coba kata kunci lain'
        : 'Coba tombol "Chat Demo" di atas untuk mulai',
        style: const TextStyle(fontSize: 13, color: Color(0xFF9C9893))),
    ]));
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: 5,
    itemBuilder: (_, __) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFFEEEBE7))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 140, height: 13,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7), color: const Color(0xFFEEEBE7))),
          const SizedBox(height: 8),
          Container(height: 11,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6), color: const Color(0xFFEEEBE7))),
        ])),
      ])));
}
