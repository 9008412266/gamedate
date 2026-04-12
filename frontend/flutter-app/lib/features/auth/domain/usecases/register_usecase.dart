import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';

class RegisterParams {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final int age;
  const RegisterParams({
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.age,
  });
}

class RegisterUseCase {
  Future<Either<Failure, void>> call(RegisterParams params) async {
    // TODO: implement real register API call
    return const Right(null);
  }
}
