import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? slogan;
  final String avatarEmoji;
  final String? avatarJsonOptions;

  const UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.slogan,
    this.avatarEmoji = '🦊',
    this.avatarJsonOptions,
  });

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? slogan,
    String? avatarEmoji,
    String? avatarJsonOptions,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl,
      slogan: slogan ?? this.slogan,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarJsonOptions: avatarJsonOptions ?? this.avatarJsonOptions,
    );
  }

  @override
  List<Object?> get props =>
      [id, username, fullName, avatarUrl, slogan, avatarEmoji, avatarJsonOptions];
}
