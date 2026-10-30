package com.chat.controller;

import com.chat.config.UserPrincipal;
import com.chat.dto.chat.AddGroupMembersRequest;
import com.chat.dto.chat.ConversationDto;
import com.chat.dto.chat.CreateDirectConversationRequest;
import com.chat.dto.chat.CreateGroupConversationRequest;
import com.chat.dto.chat.UpdateMemberRoleRequest;
import com.chat.service.ChatService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/conversations")
public class ConversationController {

    private final ChatService chatService;

    public ConversationController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping
    public ResponseEntity<List<ConversationDto>> getConversations(@AuthenticationPrincipal UserPrincipal principal) {
        List<ConversationDto> conversations = chatService.getUserConversations(principal.getId());
        return ResponseEntity.ok(conversations);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ConversationDto> getConversationById(
        @PathVariable UUID id,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        ConversationDto conversation = chatService.getConversationById(id, principal.getId());
        return ResponseEntity.ok(conversation);
    }

    @PostMapping("/direct")
    public ResponseEntity<ConversationDto> createDirectConversation(
        @Valid @RequestBody CreateDirectConversationRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        ConversationDto conversation = chatService.createOrGetDirectConversation(principal.getId(), request.getTargetUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(conversation);
    }

    @PostMapping("/group")
    public ResponseEntity<ConversationDto> createGroupConversation(
        @Valid @RequestBody CreateGroupConversationRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        ConversationDto conversation = chatService.createGroupConversation(principal.getId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(conversation);
    }

    @PostMapping("/{id}/members")
    public ResponseEntity<ConversationDto> addMembers(
        @PathVariable UUID id,
        @Valid @RequestBody AddGroupMembersRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        ConversationDto conversation = chatService.addMembersToGroup(id, principal.getId(), request);
        return ResponseEntity.ok(conversation);
    }

    @PutMapping("/{id}/members/{userId}/role")
    public ResponseEntity<ConversationDto> updateMemberRole(
        @PathVariable UUID id,
        @PathVariable UUID userId,
        @Valid @RequestBody UpdateMemberRoleRequest request,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        ConversationDto conversation = chatService.updateMemberRole(id, principal.getId(), userId, request.getRole());
        return ResponseEntity.ok(conversation);
    }

    @DeleteMapping("/{id}/members/{userId}")
    public ResponseEntity<ConversationDto> removeMember(
        @PathVariable UUID id,
        @PathVariable UUID userId,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        ConversationDto conversation = chatService.removeMemberFromGroup(id, principal.getId(), userId);
        return ResponseEntity.ok(conversation);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteConversation(
        @PathVariable UUID id,
        @AuthenticationPrincipal UserPrincipal principal
    ) {
        chatService.deleteConversation(id, principal.getId());
        return ResponseEntity.noContent().build();
    }
}
