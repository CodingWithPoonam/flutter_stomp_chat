package com.chat.dto.chat;

import com.chat.domain.MessageType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public class SendMessageRequest {

    @NotNull(message = "Conversation ID is required")
    private UUID conversationId;

    @NotBlank(message = "Message content cannot be blank")
    @Size(max = 4000, message = "Message content must not exceed 4000 characters")
    private String content;

    private MessageType type = MessageType.CHAT;

    public SendMessageRequest() {
    }

    public SendMessageRequest(UUID conversationId, String content, MessageType type) {
        this.conversationId = conversationId;
        this.content = content;
        this.type = type != null ? type : MessageType.CHAT;
    }

    public UUID getConversationId() {
        return conversationId;
    }

    public void setConversationId(UUID conversationId) {
        this.conversationId = conversationId;
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
}
