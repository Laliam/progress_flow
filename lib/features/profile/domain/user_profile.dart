import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? slogan;
  final String avatarEmoji;

  const UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.slogan,
    this.avatarEmoji = '🦊',
  });

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? slogan,
    String? avatarEmoji,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl,
      slogan: slogan ?? this.slogan,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  @override
  List<Object?> get props => [id, username, fullName, avatarUrl, slogan, avatarEmoji];
}
