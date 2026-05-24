import 'task_models.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ChatStatus { sent, read, unread }
enum ChatPartyRole { client, freelancer }
enum ChatMessageType { text, negotiation, system, file, image }
enum NegotiationStatus { pending, accepted, rejected, countered }

/// Status pengiriman pesan di sisi lokal (sebelum server konfirmasi)
enum LocalMessageStatus { pending, sent, failed }

// ─── Reaction ────────────────────────────────────────────────────────────────

class MessageReaction {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({required this.emoji, required this.userIds});

  MessageReaction copyWith({List<String>? userIds}) =>
      MessageReaction(emoji: emoji, userIds: userIds ?? this.userIds);

  Map<String, dynamic> toJson() => {'emoji': emoji, 'userIds': userIds};

  factory MessageReaction.fromJson(Map<String, dynamic> j) => MessageReaction(
        emoji: j['emoji'] as String,
        userIds: List<String>.from(j['userIds'] as List? ?? []),
      );
}

// ─── NegotiationData ─────────────────────────────────────────────────────────

class NegotiationData {
  final String title;
  final int reward;
  final String deadline;
  final NegotiationStatus status;
  final List<String> actions;

  const NegotiationData({
    required this.title,
    required this.reward,
    required this.deadline,
    required this.status,
    required this.actions,
  });
}

// ─── ChatMessage ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final ChatPartyRole sender;
  final ChatMessageType type;
  final String content;
  final String timeLabel;
  final ChatStatus status;
  final NegotiationData? negotiation;
  final String? attachment;
  final String? senderId;
  final LocalMessageStatus localStatus;
  final List<MessageReaction> reactions;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    required this.content,
    required this.timeLabel,
    required this.status,
    this.negotiation,
    this.attachment,
    this.senderId,
    this.localStatus = LocalMessageStatus.sent,
    this.reactions = const [],
    this.createdAt,
  });

  // ── Serialization untuk local storage ──────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.name,
        'type': type.name,
        'content': content,
        'timeLabel': timeLabel,
        'status': status.name,
        'attachment': attachment,
        'senderId': senderId,
        'localStatus': localStatus.name,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ChatMessage.fromLocalJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'].toString(),
        sender: ChatPartyRole.values.firstWhere(
          (e) => e.name == (j['sender'] ?? ''),
          orElse: () => ChatPartyRole.freelancer,
        ),
        type: ChatMessageType.values.firstWhere(
          (e) => e.name == (j['type'] ?? ''),
          orElse: () => ChatMessageType.text,
        ),
        content: (j['content'] ?? '') as String,
        timeLabel: (j['timeLabel'] ?? '') as String,
        status: ChatStatus.values.firstWhere(
          (e) => e.name == (j['status'] ?? ''),
          orElse: () => ChatStatus.sent,
        ),
        attachment: j['attachment'] as String?,
        senderId: j['senderId'] as String?,
        localStatus: LocalMessageStatus.values.firstWhere(
          (e) => e.name == (j['localStatus'] ?? ''),
          orElse: () => LocalMessageStatus.sent,
        ),
        reactions: (j['reactions'] as List? ?? [])
            .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );

  // ── Parse dari API Laravel ─────────────────────────────────────────────────

  factory ChatMessage.fromApiJson(
    Map<String, dynamic> json, {
    required String myUserId,
    required String clientId,
  }) {
    final senderIdStr = json['sender_id'].toString();
    final isClient    = senderIdStr == clientId;
    final isMine      = senderIdStr == myUserId;

    final senderRole = isClient
        ? ChatPartyRole.client
        : ChatPartyRole.freelancer;

    final msgType = switch (json['type'] as String? ?? 'text') {
      'file'  => ChatMessageType.file,
      'image' => ChatMessageType.image,
      _       => ChatMessageType.text,
    };

    final ChatStatus chatStatus;
    if (isMine) {
      chatStatus = json['read_at'] != null ? ChatStatus.read : ChatStatus.sent;
    } else {
      chatStatus = json['read_at'] != null ? ChatStatus.read : ChatStatus.unread;
    }

    final dt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final timeLabel = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return ChatMessage(
      id:          json['id'].toString(),
      senderId:    senderIdStr,
      sender:      senderRole,
      type:        msgType,
      content:     (json['body'] ?? '') as String,
      attachment:  json['attachment'] as String?,
      timeLabel:   timeLabel,
      status:      chatStatus,
      localStatus: LocalMessageStatus.sent,
      createdAt:   dt,
    );
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  ChatMessage copyWith({
    String? id,
    List<MessageReaction>? reactions,
    LocalMessageStatus? localStatus,
    ChatStatus? status,
    String? attachment,
  }) =>
      ChatMessage(
        id:          id ?? this.id,
        sender:      sender,
        type:        type,
        content:     content,
        timeLabel:   timeLabel,
        status:      status ?? this.status,
        negotiation: negotiation,
        attachment:  attachment ?? this.attachment,
        senderId:    senderId,
        localStatus: localStatus ?? this.localStatus,
        reactions:   reactions ?? this.reactions,
        createdAt:   createdAt,
      );
}

// ─── ChatRoom ────────────────────────────────────────────────────────────────

class ChatRoom {
  final String id;
  final String taskId;
  final String taskTitle;
  final String counterpartName;
  final String counterpartRoleLabel;
  final bool counterpartOnline;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final TaskStatus taskStatus;
  final List<ChatMessage> messages;
  final String? counterpartAvatar;
  final String? clientId;
  final String? freelancerId;

  const ChatRoom({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.counterpartName,
    required this.counterpartRoleLabel,
    required this.counterpartOnline,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.taskStatus,
    required this.messages,
    this.counterpartAvatar,
    this.clientId,
    this.freelancerId,
  });

  factory ChatRoom.fromApiJson(
    Map<String, dynamic> json, {
    required String myUserId,
    required String myRole,
  }) {
    final client     = json['client']     as Map<String, dynamic>? ?? {};
    final freelancer = json['freelancer'] as Map<String, dynamic>? ?? {};
    final task       = json['task']       as Map<String, dynamic>? ?? {};

    final bool isClient   = myRole == 'client';
    final counterpart     = isClient ? freelancer : client;
    final counterpartRole = isClient ? 'Freelancer' : 'Client';

    final rawMsgs  = json['messages'] as List<dynamic>? ?? [];
    final clientId = client['id']?.toString() ?? '';

    final messages = rawMsgs.reversed
        .map((m) => ChatMessage.fromApiJson(
              m as Map<String, dynamic>,
              myUserId: myUserId,
              clientId: clientId,
            ))
        .toList();

    final lastMsg = messages.isNotEmpty ? messages.last : null;
    final lastMsgBody = (lastMsg?.content.isNotEmpty == true)
        ? lastMsg!.content
        : (lastMsg?.attachment != null ? '📎 File' : '');

    return ChatRoom(
      id:                   json['id'].toString(),
      clientId:             clientId,
      freelancerId:         freelancer['id']?.toString(),
      taskId:               json['task_id']?.toString() ?? '',
      taskTitle:            (task['title'] ?? 'Percakapan') as String,
      counterpartName:      (counterpart['name'] ?? counterpartRole) as String,
      counterpartRoleLabel: counterpartRole,
      counterpartAvatar:    counterpart['avatar'] as String?,
      counterpartOnline:    false,
      lastMessage:          lastMsgBody,
      lastMessageTime:      lastMsg?.timeLabel ?? '',
      unreadCount:          (json['unread_count'] as int?) ?? 0,
      taskStatus:           taskStatusFromApi(task['status'] as String?),
      messages:             messages,
    );
  }

  ChatRoom copyWith({
    List<ChatMessage>? messages,
    int? unreadCount,
    String? lastMessage,
    String? lastMessageTime,
    bool? counterpartOnline,
  }) =>
      ChatRoom(
        id:                   id,
        taskId:               taskId,
        taskTitle:            taskTitle,
        counterpartName:      counterpartName,
        counterpartRoleLabel: counterpartRoleLabel,
        counterpartOnline:    counterpartOnline ?? this.counterpartOnline,
        lastMessage:          lastMessage ?? this.lastMessage,
        lastMessageTime:      lastMessageTime ?? this.lastMessageTime,
        unreadCount:          unreadCount ?? this.unreadCount,
        taskStatus:           taskStatus,
        messages:             messages ?? this.messages,
        counterpartAvatar:    counterpartAvatar,
        clientId:             clientId,
        freelancerId:         freelancerId,
      );

  // Kept for backward compat
  ChatRoom copyWithMessages(List<ChatMessage> newMessages) => copyWith(
        messages: newMessages,
        lastMessage: newMessages.isNotEmpty ? newMessages.last.content : lastMessage,
        lastMessageTime: newMessages.isNotEmpty ? newMessages.last.timeLabel : lastMessageTime,
        unreadCount: 0,
      );
}
