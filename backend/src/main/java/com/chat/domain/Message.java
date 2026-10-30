package com.chat.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "messages", indexes = {
    @Index(name = "idx_messages_conv_sent", columnList = "conversation_id, sentAt DESC"),
    @Index(name = "idx_messages_sender", columnList = "sender_id")
})
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @Column(nullable = false, length = 4000)
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MessageType type = MessageType.CHAT;

    @Column(nullable = false, updatable = false)
    private Instant sentAt;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private boolean edited = false;

    private Instant editedAt;

    @Column(nullable = false, columnDefinition = "boolean default false")
    private boolean deletedForEveryone = false;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "message_deleted_for_users", joinColumns = @JoinColumn(name = "message_id"))
    @Column(name = "user_id")
    private Set<UUID> deletedForUserIds = new HashSet<>();

    public Message() {
    }

    public Message(Conversation conversation, User sender, String content, MessageType type) {
        this.conversation = conversation;
        this.sender = sender;
        this.content = content;
        this.type = type != null ? type : MessageType.CHAT;
    }

    @PrePersist
    protected void onCreate() {
        this.sentAt = Instant.now();
        if (this.type == null) {
            this.type = MessageType.CHAT;
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Conversation getConversation() {
        return conversation;
    }

    public void setConversation(Conversation conversation) {
        this.conversation = conversation;
    }

    public User getSender() {
        return sender;
    }

    public void setSender(User sender) {
        this.sender = sender;
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

    public Set<UUID> getDeletedForUserIds() {
        return deletedForUserIds;
    }

    public void setDeletedForUserIds(Set<UUID> deletedForUserIds) {
        this.deletedForUserIds = deletedForUserIds;
    }
}
