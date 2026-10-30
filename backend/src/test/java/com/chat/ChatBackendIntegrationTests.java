package com.chat;

import com.chat.domain.ConversationType;
import com.chat.domain.MemberRole;
import com.chat.dto.auth.AuthResponse;
import com.chat.dto.auth.LoginRequest;
import com.chat.dto.auth.RegisterRequest;
import com.chat.dto.chat.AddGroupMembersRequest;
import com.chat.dto.chat.ConversationDto;
import com.chat.dto.chat.CreateGroupConversationRequest;
import com.chat.dto.chat.MessageDto;
import com.chat.dto.chat.SendMessageRequest;
import com.chat.exception.ForbiddenException;
import com.chat.service.AuthService;
import com.chat.service.ChatService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
@ActiveProfiles({"dev", "test"})
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
class ChatBackendIntegrationTests {

    @Autowired
    private AuthService authService;

    @Autowired
    private ChatService chatService;

    private AuthResponse alice;
    private AuthResponse bob;
    private AuthResponse charlie;

    @BeforeEach
    void setUp() {
        alice = authService.register(new RegisterRequest("alice", "alice@example.com", "password123", "Alice Smith"));
        bob = authService.register(new RegisterRequest("bob", "bob@example.com", "password123", "Bob Jones"));
        charlie = authService.register(new RegisterRequest("charlie", "charlie@example.com", "password123", "Charlie Brown"));
    }

    @Test
    @DisplayName("User Registration and Authentication Flow")
    void testAuthFlow() {
        assertThat(alice.getToken()).isNotBlank();
        assertThat(alice.getUser().getUsername()).isEqualTo("alice");

        AuthResponse loginRes = authService.login(new LoginRequest("alice@example.com", "password123"));
        assertThat(loginRes.getToken()).isNotBlank();
        assertThat(loginRes.getUser().getId()).isEqualTo(alice.getUser().getId());
    }

    @Test
    @DisplayName("Direct Conversation Creation and Idempotency")
    void testDirectConversation() {
        ConversationDto conv1 = chatService.createOrGetDirectConversation(alice.getUser().getId(), bob.getUser().getId());
        assertThat(conv1.getType()).isEqualTo(ConversationType.DIRECT);
        assertThat(conv1.getMembers()).hasSize(2);

        // Idempotency: calling again should return the existing conversation
        ConversationDto conv2 = chatService.createOrGetDirectConversation(bob.getUser().getId(), alice.getUser().getId());
        assertThat(conv2.getId()).isEqualTo(conv1.getId());
    }

    @Test
    @DisplayName("Group Conversation Creation with Multiple Members and Admin Role Management")
    void testGroupConversation() {
        CreateGroupConversationRequest req = new CreateGroupConversationRequest(
            "Engineering Team",
            List.of(bob.getUser().getId())
        );

        ConversationDto group = chatService.createGroupConversation(alice.getUser().getId(), req);
        assertThat(group.getType()).isEqualTo(ConversationType.GROUP);
        assertThat(group.getTitle()).isEqualTo("Engineering Team");
        assertThat(group.getMembers()).hasSize(2);

        // Alice (Creator/Admin) adds Charlie to group
        ConversationDto updated = chatService.addMembersToGroup(
            group.getId(),
            alice.getUser().getId(),
            new AddGroupMembersRequest(List.of(charlie.getUser().getId()))
        );
        assertThat(updated.getMembers()).hasSize(3);

        // Alice promotes Bob to ADMIN
        ConversationDto withAdmin = chatService.updateMemberRole(
            group.getId(),
            alice.getUser().getId(),
            bob.getUser().getId(),
            MemberRole.ADMIN
        );
        assertThat(withAdmin.getMembers().stream()
            .anyMatch(m -> m.getUserId().equals(bob.getUser().getId()) && MemberRole.ADMIN == m.getRole())
        ).isTrue();

        // Charlie (MEMBER) cannot promote anyone -> throws ForbiddenException
        assertThrows(ForbiddenException.class, () -> {
            chatService.updateMemberRole(
                group.getId(),
                charlie.getUser().getId(),
                alice.getUser().getId(),
                MemberRole.MEMBER
            );
        });
    }

    @Test
    @DisplayName("Real-time Message Persistence and History Retrieval")
    void testMessagingAndHistory() {
        ConversationDto conv = chatService.createOrGetDirectConversation(alice.getUser().getId(), bob.getUser().getId());

        SendMessageRequest msgReq = new SendMessageRequest(conv.getId(), "Hello Bob!", null);
        MessageDto sent = chatService.saveAndProcessMessage(alice.getUser().getId(), msgReq);

        assertThat(sent.getContent()).isEqualTo("Hello Bob!");
        assertThat(sent.getSenderUsername()).isEqualTo("alice");

        // Verify Bob can retrieve chat history
        Page<MessageDto> history = chatService.getChatHistory(conv.getId(), bob.getUser().getId(), PageRequest.of(0, 20));
        assertThat(history.getContent()).hasSize(1);
        assertThat(history.getContent().get(0).getContent()).isEqualTo("Hello Bob!");

        // 1. Test Edit Message
        MessageDto edited = chatService.editMessage(
            conv.getId(),
            sent.getId(),
            alice.getUser().getId(),
            new com.chat.dto.chat.EditMessageRequest("Hello Bob! (Updated)")
        );
        assertThat(edited.getContent()).isEqualTo("Hello Bob! (Updated)");
        assertThat(edited.isEdited()).isTrue();

        // 2. Test Delete for Me (Bob deletes for himself)
        chatService.deleteMessage(conv.getId(), sent.getId(), bob.getUser().getId(), false);
        Page<MessageDto> bobHistory = chatService.getChatHistory(conv.getId(), bob.getUser().getId(), PageRequest.of(0, 20));
        assertThat(bobHistory.getContent()).isEmpty();

        // Alice can still see the message
        Page<MessageDto> aliceHistory = chatService.getChatHistory(conv.getId(), alice.getUser().getId(), PageRequest.of(0, 20));
        assertThat(aliceHistory.getContent()).hasSize(1);

        // 3. Test Delete for Everyone (Alice deletes for everyone)
        MessageDto deletedForEveryone = chatService.deleteMessage(conv.getId(), sent.getId(), alice.getUser().getId(), true);
        assertThat(deletedForEveryone.isDeletedForEveryone()).isTrue();
        assertThat(deletedForEveryone.getContent()).isEqualTo("This message was deleted");

        // 4. Test Delete Conversation
        chatService.deleteConversation(conv.getId(), alice.getUser().getId());
        assertThrows(com.chat.exception.ForbiddenException.class, () -> {
            chatService.getConversationById(conv.getId(), alice.getUser().getId());
        });
    }

    @Test
    @DisplayName("Security: Non-members cannot read or post messages")
    void testSecurityNonMemberAccessDenied() {
        ConversationDto conv = chatService.createOrGetDirectConversation(alice.getUser().getId(), bob.getUser().getId());

        // Charlie is NOT a member of Alice-Bob conversation
        assertThrows(ForbiddenException.class, () -> {
            chatService.getChatHistory(conv.getId(), charlie.getUser().getId(), PageRequest.of(0, 20));
        });

        assertThrows(ForbiddenException.class, () -> {
            SendMessageRequest unauthMsg = new SendMessageRequest(conv.getId(), "Intruder message", null);
            chatService.saveAndProcessMessage(charlie.getUser().getId(), unauthMsg);
        });
    }
}
