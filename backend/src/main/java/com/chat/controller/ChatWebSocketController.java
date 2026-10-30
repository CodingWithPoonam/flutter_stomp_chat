package com.chat.controller;

import com.chat.config.UserPrincipal;
import com.chat.dto.chat.MessageDto;
import com.chat.dto.chat.SendMessageRequest;
import com.chat.dto.websocket.TypingNotification;
import com.chat.service.ChatService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
public class ChatWebSocketController {

    private static final Logger log = LoggerFactory.getLogger(ChatWebSocketController.class);

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatWebSocketController(ChatService chatService, SimpMessagingTemplate messagingTemplate) {
        this.chatService = chatService;
        this.messagingTemplate = messagingTemplate;
    }

    /**
     * Handles real-time chat messages sent via STOMP to /app/chat.send
     * Persists message to database, verifies membership, and broadcasts to /topic/conversation.{id}
     */
    @MessageMapping("/chat.send")
    public void handleSendMessage(@Payload SendMessageRequest request, Principal principal) {
        UserPrincipal userPrincipal = extractUserPrincipal(principal);

        log.info("Received real-time message from user {} for conversation {}",
            userPrincipal.getUsername(), request.getConversationId());

        MessageDto messageDto = chatService.saveAndProcessMessage(userPrincipal.getId(), request);

        // Broadcast to all conversation subscribers
        String destination = "/topic/conversation." + request.getConversationId();
        messagingTemplate.convertAndSend(destination, messageDto);
    }

    /**
     * Handles ephemeral typing indicators via STOMP to /app/chat.typing
     * Broadcasts directly to /topic/conversation.{id}.typing without database persistence
     */
    @MessageMapping("/chat.typing")
    public void handleTypingIndicator(@Payload TypingNotification notification, Principal principal) {
        UserPrincipal userPrincipal = extractUserPrincipal(principal);

        // Verify membership before broadcasting typing status
        chatService.validateMembership(notification.getConversationId(), userPrincipal.getId());

        notification.setUserId(userPrincipal.getId());
        notification.setUsername(userPrincipal.getUsername());
        notification.setDisplayName(userPrincipal.getDisplayName());

        String destination = "/topic/conversation." + notification.getConversationId() + ".typing";
        messagingTemplate.convertAndSend(destination, notification);
    }

    private UserPrincipal extractUserPrincipal(Principal principal) {
        if (principal instanceof UsernamePasswordAuthenticationToken auth &&
            auth.getPrincipal() instanceof UserPrincipal userPrincipal) {
            return userPrincipal;
        }
        throw new AccessDeniedException("User is not authenticated for STOMP action");
    }
}
