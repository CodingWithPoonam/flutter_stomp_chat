package com.chat.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public class CreateGroupConversationRequest {

    @NotBlank(message = "Group title is required")
    @Size(min = 2, max = 100, message = "Group title must be between 2 and 100 characters")
    private String title;

    @NotEmpty(message = "At least one member must be selected")
    private List<UUID> memberUserIds;

    public CreateGroupConversationRequest() {
    }

    public CreateGroupConversationRequest(String title, List<UUID> memberUserIds) {
        this.title = title;
        this.memberUserIds = memberUserIds;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public List<UUID> getMemberUserIds() {
        return memberUserIds;
    }

    public void setMemberUserIds(List<UUID> memberUserIds) {
        this.memberUserIds = memberUserIds;
    }
}
