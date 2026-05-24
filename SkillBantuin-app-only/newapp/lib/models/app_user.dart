import 'user_role.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String phoneNumber;
  final UserRole role;
  final String token;
  final String? avatar;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.phoneNumber,
    required this.role,
    required this.token,
    this.avatar,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
        'role': role.name,
        'token': token,
        'avatar': avatar,
      };

  // Dari SharedPreferences (format lama, tetap kompatibel)
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        fullName: (json['fullName'] ?? json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        username: (json['username'] ?? '') as String,
        phoneNumber:
            (json['phoneNumber'] ?? json['phone_number'] ?? '') as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == (json['role'] as String? ?? 'client'),
          orElse: () => UserRole.client,
        ),
        token: (json['token'] ?? '') as String,
        avatar: json['avatar'] as String?,
      );

  // Dari respons API Laravel —— token dioper terpisah
  factory AppUser.fromApiJson(
    Map<String, dynamic> json, {
    required String token,
  }) =>
      AppUser(
        id: json['id'].toString(),
        fullName: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        username: (json['username'] ?? '') as String,
        phoneNumber: (json['phone_number'] ?? '') as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == (json['role'] as String? ?? 'client'),
          orElse: () => UserRole.client,
        ),
        token: token,
        avatar: json['avatar'] as String?,
      );

  AppUser copyWith({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? avatar,
    String? token,
  }) =>
      AppUser(
        id: id,
        fullName: fullName ?? this.fullName,
        email: email,
        username: username ?? this.username,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        role: role,
        token: token ?? this.token,
        avatar: avatar ?? this.avatar,
      );
}
