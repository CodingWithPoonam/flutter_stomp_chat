package com.chat.dto.chat;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.UUID;

public class AddGroupMembersRequest {

    @NotEmpty(message = "Member user IDs cannot be empty")
    private List<UUID> memberUserIds;

    public AddGroupMembersRequest() {
    }

    public AddGroupMembersRequest(List<UUID> memberUserIds) {
        this.memberUserIds = memberUserIds;
    }

    public List<UUID> getMemberUserIds() {
        return memberUserIds;
    }

    public void setMemberUserIds(List<UUID> memberUserIds) {
        this.memberUserIds = memberUserIds;
    }
}
