package com.chat.dto.chat;

import com.chat.domain.Conversation;
import com.chat.domain.ConversationType;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

public class ConversationDto {
    private UUID id;
    private ConversationType type;
    private String title;
    private UUID creatorId;
    private List<MemberDto> members;
    private MessageDto lastMessage;
    private Instant createdAt;
    private Instant updatedAt;

    public ConversationDto() {
    }

    public ConversationDto(UUID id, ConversationType type, String title, UUID creatorId, List<MemberDto> members, MessageDto lastMessage, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.type = type;
        this.title = title;
        this.creatorId = creatorId;
        this.members = members;
        this.lastMessage = lastMessage;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static ConversationDto fromEntity(Conversation conversation, UUID currentUserId) {
        List<MemberDto> memberDtos = conversation.getMembers().stream()
            .map(MemberDto::fromEntity)
            .collect(Collectors.toList());

        String displayTitle = conversation.getTitle();
        if (conversation.getType() == ConversationType.DIRECT) {
            // Find the other member in this direct conversation
            var otherMember = memberDtos.stream()
                .filter(m -> !m.getUserId().equals(currentUserId))
                .findFirst();
            if (otherMember.isPresent()) {
                displayTitle = otherMember.get().getDisplayName();
            } else if (!memberDtos.isEmpty()) {
                displayTitle = memberDtos.get(0).getDisplayName();
            }
        }

        MessageDto lastMsgDto = conversation.getLastMessage() != null ?
            MessageDto.fromEntity(conversation.getLastMessage()) : null;

        return new ConversationDto(
            conversation.getId(),
            conversation.getType(),
            displayTitle,
            conversation.getCreator() != null ? conversation.getCreator().getId() : null,
            memberDtos,
            lastMsgDto,
            conversation.getCreatedAt(),
            conversation.getUpdatedAt()
        );
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public ConversationType getType() {
        return type;
    }

    public void setType(ConversationType type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public UUID getCreatorId() {
        return creatorId;
    }

    public void setCreatorId(UUID creatorId) {
        this.creatorId = creatorId;
    }

    public List<MemberDto> getMembers() {
        return members;
    }

    public void setMembers(List<MemberDto> members) {
        this.members = members;
    }

    public MessageDto getLastMessage() {
        return lastMessage;
    }

    public void setLastMessage(MessageDto lastMessage) {
        this.lastMessage = lastMessage;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
