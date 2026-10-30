package com.chat.controller;

import com.chat.config.UserPrincipal;
import com.chat.dto.chat.MessageDto;
import com.chat.dto.chat.SendMessageRequest;
import com.chat.service.ChatService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/conversations/{conversationId}/messages")
public class MessageController {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;

    public MessageController(ChatService chatService, SimpMessagingTemplate messagingTemplate) {
        this.chatService = chatService;
        this.messagingTemplate = messagingTemplate;
    }

    @GetMapping
    public ResponseEntity<Page<MessageDto>> getChatHistory(
        @PathVariable UUID conversationId,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "50") int size,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        Pageable pageable = PageRequest.of(page, Math.min(size, 100));
        Page<MessageDto> messages = chatService.getChatHistory(conversationId, principal.getId(), pageable);
        return ResponseEntity.ok(messages);
    }

    @PostMapping
    public ResponseEntity<MessageDto> sendMessage(
        @PathVariable UUID conversationId,
        @Valid @RequestBody SendMessageRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        request.setConversationId(conversationId);
        MessageDto messageDto = chatService.saveAndProcessMessage(principal.getId(), request);

        // Broadcast to STOMP topic for all subscribers of this conversation
        messagingTemplate.convertAndSend("/topic/conversation." + conversationId, messageDto);

        return ResponseEntity.status(HttpStatus.CREATED).body(messageDto);
    }

    @PutMapping("/{messageId}")
    public ResponseEntity<MessageDto> editMessage(
        @PathVariable UUID conversationId,
        @PathVariable UUID messageId,
        @Valid @RequestBody com.chat.dto.chat.EditMessageRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        MessageDto updated = chatService.editMessage(conversationId, messageId, principal.getId(), request);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{messageId}")
    public ResponseEntity<MessageDto> deleteMessage(
        @PathVariable UUID conversationId,
        @PathVariable UUID messageId,
        @RequestParam(defaultValue = "false") boolean forEveryone,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        MessageDto result = chatService.deleteMessage(conversationId, messageId, principal.getId(), forEveryone);
        return ResponseEntity.ok(result);
    }
}
