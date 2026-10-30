package com.chat.repository;

import com.chat.domain.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface MessageRepository extends JpaRepository<Message, UUID> {

    Page<Message> findByConversationIdOrderBySentAtDesc(UUID conversationId, Pageable pageable);

    @org.springframework.data.jpa.repository.Query("SELECT m FROM Message m WHERE m.conversation.id = :conversationId AND :userId NOT MEMBER OF m.deletedForUserIds ORDER BY m.sentAt DESC")
    Page<Message> findVisibleMessagesByConversationId(
        @org.springframework.data.repository.query.Param("conversationId") UUID conversationId,
        @org.springframework.data.repository.query.Param("userId") UUID userId,
        Pageable pageable
    );

    long countByConversationId(UUID conversationId);

    void deleteAllByConversationId(UUID conversationId);
}
