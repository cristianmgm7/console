import 'package:equatable/equatable.dart';

/// Domain entity representing a user
class User extends Equatable {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isVerified,
    this.avatarUrl,
    this.lastSeen,
    this.languages = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isVerified;
  final String? avatarUrl;
  final DateTime? lastSeen;
  final List<String> languages;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [id, firstName, lastName, email, isVerified, avatarUrl, lastSeen, languages];
}
