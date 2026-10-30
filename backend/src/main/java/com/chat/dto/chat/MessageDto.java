package com.chat.dto.chat;

import com.chat.domain.Message;
import com.chat.domain.MessageType;

import java.time.Instant;
import java.util.UUID;

public class MessageDto {
    private UUID id;
    private UUID conversationId;
    private UUID senderId;
    private String senderUsername;
    private String senderDisplayName;
    private String senderAvatarUrl;
    private String content;
    private MessageType type;
    private Instant sentAt;
    private boolean edited;
    private Instant editedAt;
    private boolean deletedForEveryone;

    public MessageDto() {
    }

    public MessageDto(UUID id, UUID conversationId, UUID senderId, String senderUsername, String senderDisplayName, String senderAvatarUrl, String content, MessageType type, Instant sentAt, boolean edited, Instant editedAt, boolean deletedForEveryone) {
        this.id = id;
        this.conversationId = conversationId;
        this.senderId = senderId;
        this.senderUsername = senderUsername;
        this.senderDisplayName = senderDisplayName;
        this.senderAvatarUrl = senderAvatarUrl;
        this.content = content;
        this.type = type;
        this.sentAt = sentAt;
        this.edited = edited;
        this.editedAt = editedAt;
        this.deletedForEveryone = deletedForEveryone;
    }

    public static MessageDto fromEntity(Message message) {
        return new MessageDto(
            message.getId(),
            message.getConversation().getId(),
            message.getSender().getId(),
            message.getSender().getUsername(),
            message.getSender().getDisplayName(),
            message.getSender().getAvatarUrl(),
            message.getContent(),
            message.getType(),
            message.getSentAt(),
            message.isEdited(),
            message.getEditedAt(),
            message.isDeletedForEveryone()
        );
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getConversationId() {
        return conversationId;
    }

    public void setConversationId(UUID conversationId) {
        this.conversationId = conversationId;
    }

    public UUID getSenderId() {
        return senderId;
    }

    public void setSenderId(UUID senderId) {
        this.senderId = senderId;
    }

    public String getSenderUsername() {
        return senderUsername;
    }

    public void setSenderUsername(String senderUsername) {
        this.senderUsername = senderUsername;
    }

    public String getSenderDisplayName() {
        return senderDisplayName;
    }

    public void setSenderDisplayName(String senderDisplayName) {
        this.senderDisplayName = senderDisplayName;
    }

    public String getSenderAvatarUrl() {
        return senderAvatarUrl;
    }

    public void setSenderAvatarUrl(String senderAvatarUrl) {
        this.senderAvatarUrl = senderAvatarUrl;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public MessageType getType() {
        return type;
    }

    public void setType(MessageType type) {
        this.type = type;
    }

    public Instant getSentAt() {
        return sentAt;
    }

    public void setSentAt(Instant sentAt) {
        this.sentAt = sentAt;
    }

    public boolean isEdited() {
        return edited;
    }

    public void setEdited(boolean edited) {
        this.edited = edited;
    }

    public Instant getEditedAt() {
        return editedAt;
    }

    public void setEditedAt(Instant editedAt) {
        this.editedAt = editedAt;
    }

    public boolean isDeletedForEveryone() {
        return deletedForEveryone;
    }

    public void setDeletedForEveryone(boolean deletedForEveryone) {
        this.deletedForEveryone = deletedForEveryone;
    }
}
