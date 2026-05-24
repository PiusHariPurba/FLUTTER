// freelancer_chat_room_screen.dart
// Delegate ke shared ChatRoomScreen — backward compatibility wrapper.
// FreelancerChatRoomScreen sekarang menerima ChatRoom valid, bukan dummy room.
export '../shared/chat_room_screen.dart' show ChatRoomScreen;

import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import '../../models/user_role.dart';
import '../shared/chat_room_screen.dart';

/// Wrapper untuk navigasi dari kode lama yang masih pakai FreelancerChatRoomScreen.
/// Menerima [ChatRoom] yang valid — tidak lagi menggunakan dummy room dengan id='0'.
class FreelancerChatRoomScreen extends StatelessWidget {
  final ChatRoom room;

  const FreelancerChatRoomScreen({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return ChatRoomScreen(room: room, currentRole: UserRole.freelancer);
  }
}
