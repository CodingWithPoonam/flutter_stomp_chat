package com.chat.dto.chat;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class CreateDirectConversationRequest {

    @NotNull(message = "Target user ID is required")
    private UUID targetUserId;

    public CreateDirectConversationRequest() {
    }

    public CreateDirectConversationRequest(UUID targetUserId) {
        this.targetUserId = targetUserId;
    }

    public UUID getTargetUserId() {
        return targetUserId;
    }

    public void setTargetUserId(UUID targetUserId) {
        this.targetUserId = targetUserId;
    }
}
