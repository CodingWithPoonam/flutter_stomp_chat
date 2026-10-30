import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../notifications/in_app_notification_service.dart';
import '../storage/secure_storage_service.dart';
import '../websocket/stomp_client_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';

// Conversations
import '../../features/conversations/data/datasources/conversation_remote_datasource.dart';
import '../../features/conversations/data/repositories/conversation_repository_impl.dart';
import '../../features/conversations/domain/repositories/conversation_repository.dart';
import '../../features/conversations/domain/usecases/conversation_usecases.dart';

// Chat
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/chat_usecases.dart';

final getIt = GetIt.instance;

Future<void> initServiceLocator() async {
  // 1. Core Services (Singletons)
  final storageService = SecureStorageService();
  getIt.registerSingleton<SecureStorageService>(storageService);

  final stompService = StompClientService();
  getIt.registerSingleton<StompClientService>(stompService);

  final notificationService = InAppNotificationService();
  getIt.registerSingleton<InAppNotificationService>(notificationService);

  final apiClient = ApiClient(storageService: storageService);
  getIt.registerSingleton<ApiClient>(apiClient);

  // 2. Auth Feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));

  // 3. Conversations Feature
  getIt.registerLazySingleton<ConversationRemoteDataSource>(
    () => ConversationRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(remoteDataSource: getIt<ConversationRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => GetConversationsUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => CreateDirectConversationUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => CreateGroupConversationUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => SearchUsersUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => AddGroupMembersUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => UpdateMemberRoleUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => RemoveGroupMemberUseCase(getIt<ConversationRepository>()));
  getIt.registerLazySingleton(() => DeleteConversationUseCase(getIt<ConversationRepository>()));

  // 4. Chat Feature
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      apiClient: getIt<ApiClient>(),
      stompService: getIt<StompClientService>(),
    ),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: getIt<ChatRemoteDataSource>()),
  );
  getIt.registerLazySingleton(() => GetChatHistoryUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SendTypingIndicatorUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SubscribeToMessagesUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => SubscribeToTypingUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => EditMessageUseCase(getIt<ChatRepository>()));
  getIt.registerLazySingleton(() => DeleteMessageUseCase(getIt<ChatRepository>()));
}
