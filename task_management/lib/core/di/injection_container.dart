import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../../feature/domain/i_repositories/i_auth_repository.dart';
import '../../feature/data/imp_repositories/auth_repository_imp.dart';
import '../../feature/domain/i_repositories/i_workspace_repository.dart';
import '../../feature/data/imp_repositories/workspace_repository_imp.dart';
import '../../feature/domain/i_repositories/i_task_repository.dart';
import '../../feature/data/imp_repositories/task_repository_imp.dart';
import '../../feature/domain/i_repositories/i_project_repository.dart';
import '../../feature/data/imp_repositories/project_repository_imp.dart';
import '../../feature/domain/i_repositories/i_comment_repository.dart';
import '../../feature/data/imp_repositories/comment_repository_imp.dart';
import '../../feature/domain/i_repositories/i_attachment_repository.dart';
import '../../feature/data/imp_repositories/attachment_repository_imp.dart';
import '../../feature/domain/i_repositories/i_notification_repository.dart';
import '../../feature/data/imp_repositories/notification_repository_imp.dart';
import '../../feature/domain/i_repositories/i_dashboard_repository.dart';
import '../../feature/data/imp_repositories/dashboard_repository_imp.dart';

import '../../feature/application/i_services/i_auth_service.dart';
import '../../feature/application/services/auth_service.dart';
import '../../feature/application/i_services/i_workspace_service.dart';
import '../../feature/application/services/workspace_service.dart';
import '../../feature/application/i_services/i_task_service.dart';
import '../../feature/application/services/task_service.dart';
import '../../feature/application/i_services/i_project_service.dart';
import '../../feature/application/services/project_service.dart';
import '../../feature/application/i_services/i_comment_service.dart';
import '../../feature/application/services/comment_service.dart';
import '../../feature/application/i_services/i_attachment_service.dart';
import '../../feature/application/services/attachment_service.dart';
import '../../feature/application/i_services/i_notification_service.dart';
import '../../feature/application/services/notification_service.dart';
import '../../feature/application/i_services/i_dashboard_service.dart';
import '../../feature/application/services/dashboard_service.dart';

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
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImp(
      dio: sl<DioClient>().dio,
      secureStorage: sl<SecureStorage>(),
    ),
  );
  sl.registerLazySingleton<IAuthService>(() => AuthService(sl<IAuthRepository>()));

  // ─── Feature: Workspace ───────────────────────────────────────────────────
  sl.registerLazySingleton<IWorkspaceRepository>(
    () => WorkspaceRepositoryImp(
      dio: sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<IWorkspaceService>(() => WorkspaceService(sl<IWorkspaceRepository>()));

  // ─── Feature: Project ─────────────────────────────────────────────────────
  sl.registerLazySingleton<IProjectRepository>(
    () => ProjectRepositoryImp(
      dio: sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<IProjectService>(() => ProjectService(sl<IProjectRepository>()));

  // ─── Feature: Task ────────────────────────────────────────────────────────
  sl.registerLazySingleton<ITaskRepository>(
    () => TaskRepositoryImp(
      dio: sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<ITaskService>(() => TaskService(sl<ITaskRepository>()));

  // ─── Feature: Comment ─────────────────────────────────────────────────────
  sl.registerLazySingleton<ICommentRepository>(
    () => CommentRepositoryImp(
      dio: sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<ICommentService>(() => CommentService(sl<ICommentRepository>()));

  // ─── Feature: Attachment ──────────────────────────────────────────────────
  sl.registerLazySingleton<IAttachmentRepository>(
    () => AttachmentRepositoryImp(
      dio: sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<IAttachmentService>(() => AttachmentService(sl<IAttachmentRepository>()));

  // ─── Feature: Notification ────────────────────────────────────────────────
  sl.registerLazySingleton<INotificationRepository>(
    () => NotificationRepositoryImp(
      sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<INotificationService>(() => NotificationService(sl<INotificationRepository>()));

  // ─── Feature: Dashboard ───────────────────────────────────────────────────
  sl.registerLazySingleton<IDashboardRepository>(
    () => DashboardRepositoryImp(
      sl<DioClient>().dio,
    ),
  );
  sl.registerLazySingleton<IDashboardService>(() => DashboardService(sl<IDashboardRepository>()));
}
