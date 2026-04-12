import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? profilePhotoUrl;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.profilePhotoUrl,
  });

  @override
  List<Object?> get props => [id, username, email];
}