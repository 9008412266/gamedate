import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

class LoginParams {
  final String emailOrUsername;
  final String password;
  const LoginParams({required this.emailOrUsername, required this.password});
}

class LoginUseCase {
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // TODO: implement real auth API call
    return Right(UserEntity(
      id: 'demo-user',
      username: params.emailOrUsername,
      email: params.emailOrUsername,
      displayName: 'Demo User',
    ));
  }

  Future<UserEntity?> getCurrentUser() async {
    return null; // Not logged in by default
  }

  Future<Either<Failure, UserEntity>> verifyEmail(String email, String code) async {
    return Right(UserEntity(
      id: 'demo-user',
      username: email,
      email: email,
    ));
  }
}