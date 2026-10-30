package com.chat.dto.chat;

import com.chat.domain.ConversationMember;
import com.chat.domain.MemberRole;

import java.time.Instant;
import java.util.UUID;

public class MemberDto {
    private UUID userId;
    private String username;
    private String displayName;
    private String avatarUrl;
    private MemberRole role;
    private Instant joinedAt;

    public MemberDto() {
    }

    public MemberDto(UUID userId, String username, String displayName, String avatarUrl, MemberRole role, Instant joinedAt) {
        this.userId = userId;
        this.username = username;
        this.displayName = displayName;
        this.avatarUrl = avatarUrl;
        this.role = role;
        this.joinedAt = joinedAt;
    }

    public static MemberDto fromEntity(ConversationMember member) {
        return new MemberDto(
            member.getUser().getId(),
            member.getUser().getUsername(),
            member.getUser().getDisplayName(),
            member.getUser().getAvatarUrl(),
            member.getRole(),
            member.getJoinedAt()
        );
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

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public MemberRole getRole() {
        return role;
    }

    public void setRole(MemberRole role) {
        this.role = role;
    }

    public Instant getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(Instant joinedAt) {
        this.joinedAt = joinedAt;
    }
}
