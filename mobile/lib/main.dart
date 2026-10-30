import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/notifications/in_app_notification_banner.dart';
import 'core/notifications/in_app_notification_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/websocket/stomp_client_service.dart';

// Auth
import 'features/auth/domain/usecases/auth_usecases.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';

// Conversations & Chat
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/conversations/domain/entities/conversation_entity.dart';
import 'features/conversations/domain/usecases/conversation_usecases.dart';
import 'features/conversations/presentation/bloc/conversation_bloc.dart';
import 'features/conversations/presentation/screens/conversation_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            loginUseCase: getIt<LoginUseCase>(),
            registerUseCase: getIt<RegisterUseCase>(),
            getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
            logoutUseCase: getIt<LogoutUseCase>(),
            stompClientService: getIt<StompClientService>(),
            storageService: getIt<SecureStorageService>(),
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => ConversationBloc(
            getConversationsUseCase: getIt<GetConversationsUseCase>(),
            createDirectConversationUseCase:
                getIt<CreateDirectConversationUseCase>(),
            createGroupConversationUseCase:
                getIt<CreateGroupConversationUseCase>(),
            deleteConversationUseCase:
                getIt<DeleteConversationUseCase>(),
          ),
        ),
      ],
      child: const PulseChatAppView(),
    );
  }
}

class PulseChatAppView extends StatefulWidget {
  const PulseChatAppView({super.key});

  @override
  State<PulseChatAppView> createState() => _PulseChatAppViewState();
}

class _PulseChatAppViewState extends State<PulseChatAppView> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final notificationService = getIt<InAppNotificationService>();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Pulse STOMP Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return InAppNotificationOverlay(
          notificationService: notificationService,
          onNotificationTapped: (notif) {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              final conversation = ConversationEntity(
                id: notif.conversationId,
                type: notif.isGroup ? 'GROUP' : 'DIRECT',
                title: notif.conversationTitle,
                members: const [],
                lastMessageContent: notif.messageContent,
                lastMessageSentAt: notif.sentAt,
                updatedAt: notif.sentAt,
              );

              _navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversation: conversation,
                    currentUser: authState.user,
                  ),
                ),
              );
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return ConversationListScreen(currentUser: state.user);
          }
          if (state is AuthLoading || state is AuthInitial) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ],
                ),
              ),
            );
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
