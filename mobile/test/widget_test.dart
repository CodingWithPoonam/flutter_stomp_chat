import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/notifications/in_app_notification_banner.dart';
import 'package:mobile/core/notifications/in_app_notification_service.dart';
import 'package:mobile/core/notifications/notification_model.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';
import 'package:mobile/features/chat/data/models/message_model.dart';
import 'package:mobile/features/chat/domain/entities/message_entity.dart';
import 'package:mobile/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobile/features/chat/presentation/widgets/typing_indicator_widget.dart';
import 'package:mobile/features/conversations/domain/entities/conversation_entity.dart';
import 'package:mobile/features/conversations/domain/entities/member_entity.dart';
import 'package:mobile/features/conversations/domain/usecases/conversation_usecases.dart';
import 'package:mobile/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:mobile/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:mobile/features/conversations/presentation/bloc/conversation_state.dart';

class MockGetConversationsUseCase extends Mock implements GetConversationsUseCase {}
class MockCreateDirectConversationUseCase extends Mock implements CreateDirectConversationUseCase {}
class MockCreateGroupConversationUseCase extends Mock implements CreateGroupConversationUseCase {}
class MockDeleteConversationUseCase extends Mock implements DeleteConversationUseCase {}

void main() {
  group('Data Model JSON Serialization Tests', () {
    test('UserModel should correctly parse from JSON and serialize to JSON', () {
      final json = {
        'id': 'u1',
        'username': 'alice',
        'email': 'alice@example.com',
        'displayName': 'Alice Smith',
        'avatarUrl': null,
        'status': 'ONLINE',
      };

      final model = UserModel.fromJson(json);
      expect(model.id, 'u1');
      expect(model.username, 'alice');
      expect(model.isOnline, true);

      final serialized = model.toJson();
      expect(serialized['displayName'], 'Alice Smith');
    });

    test('MessageModel should correctly parse STOMP message payload JSON with edit and delete fields', () {
      final now = DateTime.now();
      final json = {
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u1',
        'senderUsername': 'alice',
        'senderDisplayName': 'Alice Smith',
        'content': 'Hello from STOMP!',
        'type': 'CHAT',
        'sentAt': now.toIso8601String(),
        'edited': true,
        'editedAt': now.toIso8601String(),
        'deletedForEveryone': false,
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.content, 'Hello from STOMP!');
      expect(msg.senderUsername, 'alice');
      expect(msg.type, 'CHAT');
      expect(msg.isEdited, true);
      expect(msg.isDeletedForEveryone, false);
    });
  });

  group('ConversationBloc Tests', () {
    late MockGetConversationsUseCase mockGetConversations;
    late MockCreateDirectConversationUseCase mockCreateDirect;
    late MockCreateGroupConversationUseCase mockCreateGroup;
    late MockDeleteConversationUseCase mockDeleteConversation;

    final testConversations = [
      ConversationEntity(
        id: 'c1',
        type: 'DIRECT',
        title: 'Alice Smith',
        members: [
          MemberEntity(
            userId: 'u1',
            username: 'alice',
            displayName: 'Alice Smith',
            role: 'MEMBER',
            joinedAt: DateTime.now(),
          ),
        ],
        lastMessageContent: 'Hey there!',
        updatedAt: DateTime.now(),
      ),
    ];

    setUp(() {
      mockGetConversations = MockGetConversationsUseCase();
      mockCreateDirect = MockCreateDirectConversationUseCase();
      mockCreateGroup = MockCreateGroupConversationUseCase();
      mockDeleteConversation = MockDeleteConversationUseCase();
    });

    blocTest<ConversationBloc, ConversationState>(
      'emits [ConversationLoading, ConversationLoaded] when FetchConversationsRequested succeeds',
      build: () {
        when(() => mockGetConversations()).thenAnswer((_) async => testConversations);
        return ConversationBloc(
          getConversationsUseCase: mockGetConversations,
          createDirectConversationUseCase: mockCreateDirect,
          createGroupConversationUseCase: mockCreateGroup,
          deleteConversationUseCase: mockDeleteConversation,
        );
      },
      act: (bloc) => bloc.add(FetchConversationsRequested()),
      expect: () => [
        isA<ConversationLoading>(),
        isA<ConversationLoaded>().having(
          (s) => s.conversations.length,
          'conversations count',
          1,
        ),
      ],
    );

    blocTest<ConversationBloc, ConversationState>(
      'removes conversation when DeleteConversationRequested succeeds',
      build: () {
        when(() => mockDeleteConversation('c1')).thenAnswer((_) async {});
        return ConversationBloc(
          getConversationsUseCase: mockGetConversations,
          createDirectConversationUseCase: mockCreateDirect,
          createGroupConversationUseCase: mockCreateGroup,
          deleteConversationUseCase: mockDeleteConversation,
        );
      },
      seed: () => ConversationLoaded(conversations: testConversations),
      act: (bloc) => bloc.add(const DeleteConversationRequested('c1')),
      expect: () => [
        isA<ConversationLoaded>().having(
          (s) => s.conversations.isEmpty,
          'conversations is empty',
          true,
        ),
      ],
    );
  });

  group('Widget Presentation Tests', () {
    testWidgets('MessageBubble renders message content and time correctly', (tester) async {
      final message = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        senderUsername: 'alice',
        senderDisplayName: 'Alice Smith',
        content: 'Testing STOMP message bubble',
        type: 'CHAT',
        sentAt: DateTime(2026, 1, 1, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
            ),
          ),
        ),
      );

      expect(find.text('Testing STOMP message bubble'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    });

    testWidgets('MessageBubble renders (edited) badge when message was edited', (tester) async {
      final message = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        senderUsername: 'alice',
        senderDisplayName: 'Alice Smith',
        content: 'Original content was updated',
        type: 'CHAT',
        sentAt: DateTime(2026, 1, 1, 10, 30),
        isEdited: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
            ),
          ),
        ),
      );

      expect(find.text('Original content was updated'), findsOneWidget);
      expect(find.text('• (edited)'), findsOneWidget);
    });

    testWidgets('MessageBubble renders deleted placeholder when isDeletedForEveryone is true', (tester) async {
      final message = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        senderUsername: 'alice',
        senderDisplayName: 'Alice Smith',
        content: 'This message was deleted',
        type: 'CHAT',
        sentAt: DateTime(2026, 1, 1, 10, 30),
        isDeletedForEveryone: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: message,
              isMe: true,
            ),
          ),
        ),
      );

      expect(find.text('This message was deleted'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('TypingIndicatorWidget shows active typing users', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicatorWidget(
              typingUsers: {'Bob Jones'},
            ),
          ),
        ),
      );

      expect(find.text('Bob Jones is typing...'), findsOneWidget);
    });

    test('InAppNotificationService suppresses notifications for current user and active conversation', () async {
      final notifService = InAppNotificationService();
      notifService.setCurrentUserId('u1');
      notifService.setActiveConversation('c1');

      final emitted = <ChatNotification>[];
      final sub = notifService.notificationStream.listen((n) => emitted.add(n));

      // 1. Message from myself -> should be ignored
      notifService.handleIncomingMessage(
        conversationId: 'c2',
        conversationTitle: 'General',
        senderId: 'u1',
        senderDisplayName: 'Me',
        messageContent: 'Self message',
        sentAt: DateTime.now(),
      );

      // 2. Message in active conversation c1 -> should be ignored
      notifService.handleIncomingMessage(
        conversationId: 'c1',
        conversationTitle: 'Current Chat',
        senderId: 'u2',
        senderDisplayName: 'Bob',
        messageContent: 'Message in active chat',
        sentAt: DateTime.now(),
      );

      // 3. Message in another conversation c2 from Bob -> SHOULD trigger notification!
      notifService.handleIncomingMessage(
        conversationId: 'c2',
        conversationTitle: 'Engineering Group',
        senderId: 'u2',
        senderDisplayName: 'Bob',
        messageContent: 'Hey checkout this PR!',
        sentAt: DateTime.now(),
        isGroup: true,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, 1);
      expect(emitted.first.messageContent, 'Hey checkout this PR!');
      expect(emitted.first.conversationTitle, 'Engineering Group');

      await sub.cancel();
      notifService.dispose();
    });

    testWidgets('InAppNotificationOverlay renders incoming notification banner', (tester) async {
      final notifService = InAppNotificationService();
      ChatNotification? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppNotificationOverlay(
              notificationService: notifService,
              onNotificationTapped: (n) => tapped = n,
              child: const Center(child: Text('App Main Screen')),
            ),
          ),
        ),
      );

      expect(find.text('App Main Screen'), findsOneWidget);

      // Send incoming notification
      notifService.handleIncomingMessage(
        conversationId: 'c_test',
        conversationTitle: 'Dev Team',
        senderId: 'u_alice',
        senderDisplayName: 'Alice',
        messageContent: 'Server deployed successfully!',
        sentAt: DateTime.now(),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Server deployed successfully!'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);

      // Tap on notification
      await tester.tap(find.text('Server deployed successfully!'));
      await tester.pumpAndSettle();

      expect(tapped, isNotNull);
      expect(tapped?.conversationId, 'c_test');

      notifService.dispose();
    });
  });
}
