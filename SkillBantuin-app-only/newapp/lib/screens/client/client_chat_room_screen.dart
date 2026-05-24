// client_chat_room_screen.dart
// Re-export ke ChatRoomScreen — backward compatibility wrapper.
// ClientChatRoomScreen sekarang menerima ChatRoom + role yang benar,
// bukan dummy data dengan id='0' yang tidak bisa load pesan.
export '../shared/chat_room_screen.dart' show ChatRoomScreen;

import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import '../../models/user_role.dart';
import '../shared/chat_room_screen.dart';

/// Wrapper untuk navigasi dari kode lama yang masih pakai ClientChatRoomScreen.
/// Menerima [ChatRoom] yang valid — tidak lagi menggunakan dummy room.
class ClientChatRoomScreen extends StatelessWidget {
  final ChatRoom room;

  const ClientChatRoomScreen({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return ChatRoomScreen(room: room, currentRole: UserRole.client);
  }
}
