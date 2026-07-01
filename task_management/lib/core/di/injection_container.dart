import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Registers all dependencies.
/// Call [init] once in [main] before [runApp].
Future<void> init() async {
  // ─── External ─────────────────────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      wOptions: WindowsOptions(),
    ),
  );

  // ─── Storage ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SecureStorage>(
    () => SecureStorage(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorage(sl<SharedPreferences>()),
  );

  // ─── Network ──────────────────────────────────────────────────────────────
  // We need a raw Dio instance first for the AuthInterceptor's refresh call.
  final rawDio = Dio();
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      secureStorage: sl<SecureStorage>(),
      dio: rawDio,
    ),
  );

  sl.registerLazySingleton<DioClient>(
    () => DioClient(authInterceptor: sl<AuthInterceptor>()),
  );

  // ─── Feature: Auth ────────────────────────────────────────────────────────
  // TODO: Register auth repositories and use-cases here when implemented.
  // Example:
  // sl.registerLazySingleton<IAuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remoteDataSource: AuthRemoteDataSource(sl<DioClient>().dio),
  //     secureStorage: sl<SecureStorage>(),
  //   ),
  // );
  // sl.registerLazySingleton(() => LoginUseCase(sl()));
  // sl.registerLazySingleton(() => RegisterUseCase(sl()));
  // sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // ─── Feature: Workspace ───────────────────────────────────────────────────
  // TODO: sl.registerLazySingleton<IWorkspaceRepository>(...)

  // ─── Feature: Project ─────────────────────────────────────────────────────
  // TODO: sl.registerLazySingleton<IProjectRepository>(...)

  // ─── Feature: Task ────────────────────────────────────────────────────────
  // TODO: sl.registerLazySingleton<ITaskRepository>(...)

  // ─── Feature: Notification ───────────────────────────────────────────────
  // TODO: sl.registerLazySingleton<INotificationRepository>(...)
}
