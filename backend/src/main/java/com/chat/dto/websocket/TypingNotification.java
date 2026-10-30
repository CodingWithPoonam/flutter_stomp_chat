package com.chat.dto.websocket;

import java.util.UUID;

public class TypingNotification {
    private UUID conversationId;
    private UUID userId;
    private String username;
    private String displayName;
    private boolean typing;

    public TypingNotification() {
    }

    public TypingNotification(UUID conversationId, UUID userId, String username, String displayName, boolean typing) {
        this.conversationId = conversationId;
        this.userId = userId;
        this.username = username;
        this.displayName = displayName;
        this.typing = typing;
    }

    public UUID getConversationId() {
        return conversationId;
    }

    public void setConversationId(UUID conversationId) {
        this.conversationId = conversationId;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public boolean isTyping() {
        return typing;
    }

    public void setTyping(boolean typing) {
        this.typing = typing;
    }
}
