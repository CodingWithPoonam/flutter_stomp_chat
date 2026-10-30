package com.chat.config;

import com.chat.dto.auth.RegisterRequest;
import com.chat.dto.chat.CreateGroupConversationRequest;
import com.chat.dto.chat.SendMessageRequest;
import com.chat.repository.UserRepository;
import com.chat.service.AuthService;
import com.chat.service.ChatService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
@Profile("!test")
public class DataInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    private final UserRepository userRepository;
    private final AuthService authService;
    private final ChatService chatService;

    public DataInitializer(UserRepository userRepository, AuthService authService, ChatService chatService) {
        this.userRepository = userRepository;
        this.authService = authService;
        this.chatService = chatService;
    }

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            log.info("Users already initialized, skipping seed data.");
            if (!userRepository.existsByUsername("test")) {
                authService.register(new RegisterRequest(
                    "test",
                    "test@example.com",
                    "password123",
                    "Test User"
                ));
                log.info("Test demo account ensured.");
            }
            return;
        }

        log.info("Seeding demo accounts: Alice, Bob, and Charlie...");

        var aliceRes = authService.register(new RegisterRequest(
            "alice",
            "alice@example.com",
            "password123",
            "Alice Smith"
        ));

        var bobRes = authService.register(new RegisterRequest(
            "bob",
            "bob@example.com",
            "password123",
            "Bob Jones"
        ));

        var charlieRes = authService.register(new RegisterRequest(
            "charlie",
            "charlie@example.com",
            "password123",
            "Charlie Brown"
        ));

        authService.register(new RegisterRequest(
            "test",
            "test@example.com",
            "password123",
            "Test User"
        ));

        UUID aliceId = aliceRes.getUser().getId();
        UUID bobId = bobRes.getUser().getId();
        UUID charlieId = charlieRes.getUser().getId();

        // 1. Create a Direct Conversation between Alice and Bob
        var directConv = chatService.createOrGetDirectConversation(aliceId, bobId);
        chatService.saveAndProcessMessage(
            aliceId,
            new SendMessageRequest(directConv.getId(), "Hey Bob! Welcome to the real-time STOMP chat app 🚀", null)
        );
        chatService.saveAndProcessMessage(
            bobId,
            new SendMessageRequest(directConv.getId(), "Hey Alice! The WebSocket connection is super responsive! ⚡", null)
        );

        // 2. Create an Engineering Team Group Conversation
        var groupConv = chatService.createGroupConversation(
            aliceId,
            new CreateGroupConversationRequest(
                "Engineering Team",
                List.of(bobId, charlieId)
            )
        );
        chatService.saveAndProcessMessage(
            aliceId,
            new SendMessageRequest(groupConv.getId(), "Welcome team! Let's collaborate in real-time.", null)
        );

        log.info("Demo data initialized successfully with users and initial conversations.");
    }
}
