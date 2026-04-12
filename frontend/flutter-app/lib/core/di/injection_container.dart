import 'package:get_it/get_it.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Use cases
  sl.registerLazySingleton(() => LoginUseCase());
  sl.registerLazySingleton(() => RegisterUseCase());
  sl.registerLazySingleton(() => LogoutUseCase());

  // BLoCs
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
    logoutUseCase: sl(),
  ));
  sl.registerFactory(() => WalletBloc());
}
